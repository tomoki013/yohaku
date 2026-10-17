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

/// What leaves the device. The shared support API accepts only the sources it
/// knows and, once enforced, only requests carrying the shared client key.
final class SupportAPIRequestTests: XCTestCase {
    private final class RecordingClient: SupportAPIClientProtocol, @unchecked Sendable {
        private(set) var sent: [SupportRequest] = []

        func submit(_ request: SupportRequest) async throws -> SupportResponse {
            sent.append(request)
            return SupportResponse(requestId: request.requestId)
        }
    }

    private func sampleRequest() -> SupportRequest {
        SupportRequest(
            requestId: UUID(),
            clientId: UUID(),
            source: "yohaku-ios",
            app: "yohaku",
            category: .bug,
            name: "",
            email: "",
            message: "置いた余白が翌日に消えていました。",
            appVersion: "1.0.1",
            buildNumber: "4",
            osVersion: "iOS 26.0",
            locale: "ja_JP",
            submittedAt: Date(timeIntervalSince1970: 0),
            website: ""
        )
    }

    func testPostsToTheVersionedPath() throws {
        let request = try SupportAPIClient(clientKey: nil).urlRequest(for: sampleRequest())

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://api.tmkch.io/api/v1/support")
    }

    func testPresentsTheClientKeyWhenTheBuildHasOne() throws {
        let request = try SupportAPIClient(clientKey: "shared-key").urlRequest(for: sampleRequest())

        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Support-Client"), "shared-key")
    }

    func testSendsNoKeyHeaderWithoutAKey() throws {
        let request = try SupportAPIClient(clientKey: nil).urlRequest(for: sampleRequest())

        XCTAssertNil(request.value(forHTTPHeaderField: "X-Support-Client"))
    }

    @MainActor
    func testTheFormIdentifiesItselfAsYohaku() async throws {
        let client = RecordingClient()
        let viewModel = SupportViewModel(apiClient: client)
        viewModel.category = .bug
        viewModel.subject = "余白が消える"
        viewModel.message = "置いた余白が翌日に消えていました。"

        await viewModel.submit()

        let sent = try XCTUnwrap(client.sent.first)
        XCTAssertEqual(sent.source, "yohaku-ios")
        XCTAssertEqual(sent.app, "yohaku")
    }
}
