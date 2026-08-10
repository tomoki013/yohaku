import Foundation

extension Notification.Name {
    static let yohakuBlockPlaced = Notification.Name("YohakuBlockPlaced")
}

enum ReviewRequestPolicy {
    static let minimumLaunchCount = 3
    static let minimumBlockCount = 5
    static let minimumEndedBlockCount = 3

    static func isEligible(
        blocks: [YohakuBlock],
        now: Date,
        launchCount: Int,
        lastRequestedVersion: String?,
        currentVersion: String,
        didPresentReflectionThisSession: Bool
    ) -> Bool {
        guard !didPresentReflectionThisSession,
              launchCount >= minimumLaunchCount,
              blocks.count >= minimumBlockCount,
              lastRequestedVersion != currentVersion else {
            return false
        }

        return blocks.lazy.filter { $0.endTime <= now }.prefix(minimumEndedBlockCount).count
            >= minimumEndedBlockCount
    }
}

enum ReviewRequestTracker {
    private static let launchCountKey = "review.launchCount"
    private static let lastRequestedVersionKey = "review.lastRequestedVersion"

    static var launchCount: Int {
        UserDefaults.standard.integer(forKey: launchCountKey)
    }

    static var lastRequestedVersion: String? {
        UserDefaults.standard.string(forKey: lastRequestedVersionKey)
    }

    @discardableResult
    static func recordLaunch() -> Int {
        let newCount = launchCount + 1
        UserDefaults.standard.set(newCount, forKey: launchCountKey)
        return newCount
    }

    static func markRequested(for version: String) {
        UserDefaults.standard.set(version, forKey: lastRequestedVersionKey)
    }
}
