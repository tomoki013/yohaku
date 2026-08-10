import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class SupportPurchaseStore {
    static let productID = "io.tmkch.yohaku.removeads"

    private(set) var product: Product?
    private(set) var hasRemovedAds = false
    private(set) var entitlementCheckCompleted = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var displayPrice: String? {
        if let displayPrice = product?.displayPrice {
            return displayPrice
        }
        #if DEBUG
        // UI tests launch outside the app scheme's StoreKit session. Mirror
        // the local Yohaku.storekit price only for generated review images.
        if ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") {
            return "¥400"
        }
        #endif
        return nil
    }

    @ObservationIgnored
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = observeTransactions()
        Task {
            await refreshEntitlements()
            await loadProduct()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func purchase() async {
        guard let product else {
            await loadProduct()
            guard let product = self.product else { return }
            await purchase(product)
            return
        }
        await purchase(product)
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func loadProduct() async {
        isLoading = true
        defer { isLoading = false }

        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        var isEntitled = false
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? verified(entitlement) else { continue }
            if transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                isEntitled = true
            }
        }
        hasRemovedAds = isEntitled
        entitlementCheckCompleted = true
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self,
                      let transaction = try? self.verified(update) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PurchaseVerificationError.failed
        }
    }
}

private enum PurchaseVerificationError: Error {
    case failed
}
