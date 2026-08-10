import Foundation
import SwiftData

@Model
final class YohakuBlock {
    var id: UUID
    var title: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var createdAt: Date
    var updatedAt: Date
    var reflectionResponseRawValue: String?
    var reflectionPresentedAt: Date?
    var reflectionRespondedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        startTime: Date,
        endTime: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        reflectionResponseRawValue: String? = nil,
        reflectionPresentedAt: Date? = nil,
        reflectionRespondedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reflectionResponseRawValue = reflectionResponseRawValue
        self.reflectionPresentedAt = reflectionPresentedAt
        self.reflectionRespondedAt = reflectionRespondedAt
    }
}
