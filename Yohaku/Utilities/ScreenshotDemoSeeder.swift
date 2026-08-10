#if DEBUG
import Foundation
import SwiftData

@MainActor
enum ScreenshotDemoSeeder {
    private static var hasSeeded = false

    static func seedIfRequested(in context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-ScreenshotMode"),
              !hasSeeded else { return }
        hasSeeded = true

        let existing = (try? context.fetch(FetchDescriptor<YohakuBlock>())) ?? []
        existing.forEach(context.delete)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Names come from the same `name.pool.N` catalog the add sheet suggests,
        // so demo data reads naturally in all 18 localizations instead of
        // leaving Japanese or English text inside a screenshot for another store.
        let samples: [(day: Int, startHour: Int, startMinute: Int, duration: Int, nameKey: Int)] = [
            (0, 10, 0, 30, 1),
            (0, 15, 0, 45, 5),
            (-1, 12, 30, 30, 3),
            (-3, 18, 0, 60, 10),
            (2, 8, 0, 20, 2),
            (5, 14, 0, 60, 9),
            (-8, 11, 0, 45, 6),
            (-13, 16, 0, 30, 7),
        ]

        for sample in samples {
            guard let date = calendar.date(byAdding: .day, value: sample.day, to: today),
                  let start = calendar.date(
                    bySettingHour: sample.startHour,
                    minute: sample.startMinute,
                    second: 0,
                    of: date
                  ),
                  let end = calendar.date(byAdding: .minute, value: sample.duration, to: start) else {
                continue
            }
            context.insert(
                YohakuBlock(
                    title: poolName(sample.nameKey),
                    date: date,
                    startTime: start,
                    endTime: end
                )
            )
        }

        if ProcessInfo.processInfo.arguments.contains("-ReflectionPreview"),
           let start = calendar.date(byAdding: .minute, value: -60, to: Date()),
           let end = calendar.date(byAdding: .minute, value: -30, to: Date()) {
            context.insert(
                YohakuBlock(
                    title: poolName(1),
                    date: calendar.startOfDay(for: end),
                    startTime: start,
                    endTime: end
                )
            )
        }

        try? context.save()
    }

    private static func poolName(_ index: Int) -> String {
        NSLocalizedString("name.pool.\(index)", comment: "")
    }
}
#endif
