import XCTest
@testable import Yohaku

final class YohakuExperiencePolicyTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private let blockID = UUID(uuidString: "8D90D35E-49B8-41C5-985B-F1D72750A7BD")!

    func testNotificationUsesStableLeadBetweenThreeAndSevenMinutes() {
        let start = now.addingTimeInterval(30 * 60)
        let first = NotificationManager.notificationDate(for: start, now: now, blockID: blockID)
        let second = NotificationManager.notificationDate(for: start, now: now, blockID: blockID)
        let leadTime = start.timeIntervalSince(try! XCTUnwrap(first))

        XCTAssertEqual(first, second)
        XCTAssertGreaterThanOrEqual(leadTime, 3 * 60)
        XCTAssertLessThanOrEqual(leadTime, 7 * 60)
    }

    func testShortNoticeNotificationUsesHalfOfRemainingTime() {
        let start = now.addingTimeInterval(4 * 60)
        XCTAssertEqual(
            NotificationManager.notificationDate(for: start, now: now, blockID: blockID),
            now.addingTimeInterval(2 * 60)
        )
    }

    func testNotificationIsSkippedWhenLessThanOneMinuteRemains() {
        XCTAssertNil(
            NotificationManager.notificationDate(
                for: now.addingTimeInterval(60),
                now: now,
                blockID: blockID
            )
        )
    }

    func testReflectionChoosesOnlyUnpresentedEndedBlocksNewestFirst() {
        let older = block(ending: now.addingTimeInterval(-120))
        let newer = block(ending: now.addingTimeInterval(-60))
        let alreadyPresented = block(ending: now.addingTimeInterval(-30))
        alreadyPresented.reflectionPresentedAt = now
        let future = block(ending: now.addingTimeInterval(60))

        let result = YohakuReflectionPolicy.unpresentedEndedBlocks(
            from: [older, future, alreadyPresented, newer],
            now: now
        )

        XCTAssertEqual(result.map(\.id), [newer.id, older.id])
    }

    func testReviewBecomesEligibleAfterRepeatedUse() {
        let blocks = (0..<5).map { index in
            block(ending: now.addingTimeInterval(TimeInterval(-60 * (index + 1))))
        }

        XCTAssertTrue(ReviewRequestPolicy.isEligible(
            blocks: blocks,
            now: now,
            launchCount: 3,
            lastRequestedVersion: nil,
            currentVersion: "1.0",
            didPresentReflectionThisSession: false
        ))
    }

    func testReviewIsNotEligibleAlongsideReflectionOrTwiceInOneVersion() {
        let blocks = (0..<5).map { index in
            block(ending: now.addingTimeInterval(TimeInterval(-60 * (index + 1))))
        }

        XCTAssertFalse(ReviewRequestPolicy.isEligible(
            blocks: blocks,
            now: now,
            launchCount: 3,
            lastRequestedVersion: nil,
            currentVersion: "1.0",
            didPresentReflectionThisSession: true
        ))
        XCTAssertFalse(ReviewRequestPolicy.isEligible(
            blocks: blocks,
            now: now,
            launchCount: 3,
            lastRequestedVersion: "1.0",
            currentVersion: "1.0",
            didPresentReflectionThisSession: false
        ))
    }

    private func block(ending endTime: Date) -> YohakuBlock {
        YohakuBlock(
            title: "Space",
            date: endTime,
            startTime: endTime.addingTimeInterval(-30 * 60),
            endTime: endTime
        )
    }
}
