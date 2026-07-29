import Foundation
import Observation
import UIKit

enum SupportAPIConfiguration {
    static let endpoint = URL(string: "https://tomokichi-api.tomoki-ttttt.workers.dev/api/support")!
}

enum SupportCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case question
    case bug
    case feature
    case other

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .question: "support.category.question"
        case .bug: "support.category.bug"
        case .feature: "support.category.feature"
        case .other: "support.category.other"
        }
    }
}

struct SupportRequest: Codable, Sendable {
    let requestId: UUID
    let clientId: UUID
    let source: String
    let app: String
    let category: SupportCategory
    let name: String
    let email: String
    let message: String
    let appVersion: String
    let buildNumber: String
    let osVersion: String
    let locale: String
    let submittedAt: Date
    let website: String
}

struct SupportResponse: Codable, Equatable, Sendable {
    let requestId: UUID

    private enum CodingKeys: String, CodingKey {
        case requestId
        case receiptId
        case id
        case data
    }

    private struct NestedResponse: Decodable {
        let requestId: UUID?
        let receiptId: UUID?
        let id: UUID?
    }

    init(requestId: UUID) {
        self.requestId = requestId
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let requestId = try container.decodeIfPresent(UUID.self, forKey: .requestId) {
            self.requestId = requestId
        } else if let receiptId = try container.decodeIfPresent(UUID.self, forKey: .receiptId) {
            self.requestId = receiptId
        } else if let id = try container.decodeIfPresent(UUID.self, forKey: .id) {
            self.requestId = id
        } else if let data = try container.decodeIfPresent(NestedResponse.self, forKey: .data),
                  let nestedID = data.requestId ?? data.receiptId ?? data.id {
            self.requestId = nestedID
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.requestId,
                .init(codingPath: decoder.codingPath, debugDescription: "A request or receipt ID is required.")
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(requestId, forKey: .requestId)
    }
}

enum SupportAPIError: LocalizedError, Equatable, Sendable {
    case invalidRequest
    case rateLimited
    case deliveryFailed
    case serverError
    case networkUnavailable
    case timedOut
    case invalidResponse

    var errorDescription: String? {
        let key: String
        switch self {
        case .invalidRequest: key = "support.error.invalid_request"
        case .rateLimited: key = "support.error.rate_limited"
        case .deliveryFailed: key = "support.error.delivery_failed"
        case .serverError: key = "support.error.server"
        case .networkUnavailable: key = "support.error.network"
        case .timedOut: key = "support.error.timed_out"
        case .invalidResponse: key = "support.error.invalid_response"
        }
        return NSLocalizedString(key, comment: "")
    }
}

protocol SupportAPIClientProtocol: Sendable {
    func submit(_ request: SupportRequest) async throws -> SupportResponse
}

struct SupportAPIClient: SupportAPIClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func submit(_ request: SupportRequest) async throws -> SupportResponse {
        var urlRequest = URLRequest(url: SupportAPIConfiguration.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 20
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let body = try? encoder.encode(request) else {
            throw SupportAPIError.invalidRequest
        }
        urlRequest.httpBody = body

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let response = response as? HTTPURLResponse else {
                throw SupportAPIError.invalidResponse
            }
            guard (200..<300).contains(response.statusCode) else {
                throw Self.apiError(statusCode: response.statusCode, data: data)
            }

            if let response = try? JSONDecoder().decode(SupportResponse.self, from: data) {
                return response
            }
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               object["ok"] as? Bool == true || object["success"] as? Bool == true {
                return SupportResponse(requestId: request.requestId)
            }
            throw SupportAPIError.invalidResponse
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as SupportAPIError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw SupportAPIError.timedOut
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
                 .cannotFindHost, .dnsLookupFailed, .internationalRoamingOff, .dataNotAllowed:
                throw SupportAPIError.networkUnavailable
            default:
                throw SupportAPIError.networkUnavailable
            }
        } catch {
            throw SupportAPIError.networkUnavailable
        }
    }

    private struct ErrorEnvelope: Decodable {
        let code: String?
    }

    private static func apiError(statusCode: Int, data: Data) -> SupportAPIError {
        let code = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data).code)?
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")

        switch code {
        case "invalid_request", "validation_error": return .invalidRequest
        case "rate_limited", "too_many_requests": return .rateLimited
        case "delivery_failed", "email_delivery_failed": return .deliveryFailed
        default:
            switch statusCode {
            case 400, 422: return .invalidRequest
            case 429: return .rateLimited
            case 502: return .deliveryFailed
            case 500...599: return .serverError
            default: return .invalidResponse
            }
        }
    }
}

private struct SupportClientIDStore {
    static let key = "supportClientId"

    func clientID() -> UUID {
        if let value = UserDefaults.standard.string(forKey: Self.key),
           let id = UUID(uuidString: value) {
            return id
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: Self.key)
        return id
    }
}

@MainActor
@Observable
final class SupportViewModel {
    enum SubmissionState: Equatable {
        case idle
        case submitting
        case success(SupportResponse)
        case failure(SupportAPIError)
    }

    var category: SupportCategory = .question
    var name = ""
    var subject = ""
    var email = ""
    var message = ""
    private(set) var state: SubmissionState = .idle

    private let apiClient: any SupportAPIClientProtocol
    private let clientIDStore = SupportClientIDStore()
    private var requestId = UUID()

    init(apiClient: any SupportAPIClientProtocol = SupportAPIClient()) {
        self.apiClient = apiClient
    }

    var isSubmitting: Bool { state == .submitting }

    var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailParts = trimmedEmail.split(separator: "@", omittingEmptySubsequences: false)
        let isEmailValid = emailParts.count == 2 &&
            !emailParts[0].isEmpty &&
            emailParts[1].contains(".") &&
            !trimmedEmail.contains(where: \.isWhitespace)
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        return isEmailValid &&
            name.count <= 100 &&
            !trimmedSubject.isEmpty &&
            trimmedSubject.count <= 200 &&
            (10...5000).contains(message.count) &&
            !isSubmitting
    }

    func submit() async {
        guard canSubmit else { return }
        state = .submitting

        let request = SupportRequest(
            requestId: requestId,
            clientId: clientIDStore.clientID(),
            source: "yohaku-ios",
            app: "yohaku",
            category: category,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            message: "\(NSLocalizedString("support.subject_prefix", comment: "")): \(subject.trimmingCharacters(in: .whitespacesAndNewlines))\n\n\(message)",
            appVersion: AppInfo.version,
            buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1",
            osVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            locale: Locale.current.identifier,
            submittedAt: Date(),
            website: ""
        )

        do {
            state = .success(try await apiClient.submit(request))
        } catch is CancellationError {
            state = .idle
        } catch let error as SupportAPIError {
            state = .failure(error)
        } catch {
            state = .failure(.networkUnavailable)
        }
    }

    func startNewInquiry() {
        category = .question
        name = ""
        subject = ""
        email = ""
        message = ""
        requestId = UUID()
        state = .idle
    }
}
