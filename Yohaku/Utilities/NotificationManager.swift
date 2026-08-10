import Foundation
import UserNotifications

enum NotificationManager {
    private static let enabledKey = "notificationsEnabled"

    static var isEnabled: Bool {
        (UserDefaults.standard.object(forKey: enabledKey) as? Bool) ?? false
    }

    // トグルが一度でも確定したか(初回許可の結果、または明示的な操作)
    private static var hasStoredPreference: Bool {
        UserDefaults.standard.object(forKey: enabledKey) != nil
    }

    // 最初の余白が置かれた時だけ許可を求め、許可されたらトグルをオンにする。
    // 一度オフが確定した後は何もしない(明示的なオフを尊重する)
    static func requestInitialAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        guard !hasStoredPreference else {
            completion(isEnabled)
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: enabledKey)
                completion(granted)
            }
        }
    }

    // トグルをオンにした時に呼ぶ。OS のポップは未確定の時しか出ず、
    // 確定済みなら既存の許可状態がそのまま返る
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func schedule(for block: YohakuBlock) {
        cancel(id: block.id)
        let now = Date()
        guard isEnabled,
              let notificationDate = notificationDate(
                for: block.startTime,
                now: now,
                blockID: block.id
              ) else { return }

        let content = UNMutableNotificationContent()
        content.title = block.title
        content.body = String(localized: "notification.message")
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: block.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Uses a stable, per-space lead time between three and seven minutes so
    /// rescheduling the same space does not unexpectedly move its notification.
    /// For a space created at short notice, use half of the remaining time while
    /// keeping at least one minute.
    static func notificationDate(for startTime: Date, now: Date, blockID: UUID) -> Date? {
        let remaining = startTime.timeIntervalSince(now)
        guard remaining > 60 else { return nil }
        let leadTime = min(randomizedLeadTime(for: blockID), max(60, remaining / 2))
        return startTime.addingTimeInterval(-leadTime)
    }

    static func randomizedLeadTime(for blockID: UUID) -> TimeInterval {
        // Swift's Hashable seed changes between launches, so use a tiny stable
        // hash of the UUID instead. Five buckets map to 3, 4, 5, 6, or 7 minutes.
        let hash = blockID.uuidString.utf8.reduce(UInt64(14_695_981_039_346_656_037)) {
            ($0 ^ UInt64($1)) &* 1_099_511_628_211
        }
        return TimeInterval(3 + (hash % 5)) * 60
    }

    static func cancel(id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func rescheduleAll(_ blocks: [YohakuBlock]) {
        cancelAll()
        for block in blocks {
            schedule(for: block)
        }
    }
}
