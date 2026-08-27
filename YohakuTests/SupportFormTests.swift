import XCTest
@testable import Yohaku

@MainActor
final class SupportFormTests: XCTestCase {
    private func filledViewModel(category: SupportCategory) -> SupportViewModel {
        let viewModel = SupportViewModel()
        viewModel.category = category
        viewModel.subject = "余白が消える"
        viewModel.message = "置いた余白が翌日に消えていました。"
        return viewModel
    }

    func testQuestionCategoryRequiresAnAddressWithoutAskingFirst() {
        let viewModel = filledViewModel(category: .question)

        XCTAssertFalse(viewModel.showsReplyToggle)
        XCTAssertTrue(viewModel.requiresEmail)
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.email = "reader@example.com"
        XCTAssertTrue(viewModel.canSubmit)
        XCTAssertEqual(viewModel.outgoingEmail, "reader@example.com")
    }

    func testOtherCategoriesSendWithoutAnAddress() {
        for category in [SupportCategory.bug, .feature, .other] {
            let viewModel = filledViewModel(category: category)

            XCTAssertTrue(viewModel.showsReplyToggle, "\(category)")
            XCTAssertFalse(viewModel.requiresEmail, "\(category)")
            XCTAssertTrue(viewModel.canSubmit, "\(category)")
            XCTAssertEqual(viewModel.outgoingEmail, "", "\(category)")
        }
    }

    func testAskingForAReplyMakesTheAddressRequired() {
        let viewModel = filledViewModel(category: .bug)
        viewModel.wantsReply = true

        XCTAssertTrue(viewModel.requiresEmail)
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.email = "not-an-address"
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.email = "reader@example.com"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testTurningTheReplyToggleBackOffWithholdsTheAddress() {
        let viewModel = filledViewModel(category: .feature)
        viewModel.wantsReply = true
        viewModel.email = "reader@example.com"
        viewModel.wantsReply = false

        // The typed value stays in the form so turning the toggle back on does
        // not lose it, but nothing leaves the device.
        XCTAssertEqual(viewModel.email, "reader@example.com")
        XCTAssertEqual(viewModel.outgoingEmail, "")
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testChangingCategoryMovesTheRequirementAndKeepsInput() {
        let viewModel = filledViewModel(category: .bug)
        viewModel.category = .question

        XCTAssertTrue(viewModel.requiresEmail)
        XCTAssertEqual(viewModel.subject, "余白が消える")

        viewModel.category = .bug
        XCTAssertFalse(viewModel.requiresEmail)
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testStartingANewInquiryClearsTheReplyRequest() {
        let viewModel = filledViewModel(category: .bug)
        viewModel.wantsReply = true
        viewModel.email = "reader@example.com"

        viewModel.startNewInquiry()

        XCTAssertFalse(viewModel.wantsReply)
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.category, .question)
    }
}
