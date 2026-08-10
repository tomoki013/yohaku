import Foundation

enum YohakuReflectionResponse: String, CaseIterable, Identifiable {
    case spent
    case partly
    case skipped

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .spent: "reflection.spent"
        case .partly: "reflection.partly"
        case .skipped: "reflection.skipped"
        }
    }
}

enum YohakuReflectionPolicy {
    static func unpresentedEndedBlocks(
        from blocks: [YohakuBlock],
        now: Date
    ) -> [YohakuBlock] {
        blocks
            .filter { $0.endTime <= now && $0.reflectionPresentedAt == nil }
            .sorted { $0.endTime > $1.endTime }
    }
}
