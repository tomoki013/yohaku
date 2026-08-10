import XCTest

final class YohakuExperienceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testReflectionCardCanBeDismissedWithoutAnswer() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ScreenshotMode",
            "-ReflectionPreview",
            "-AppleLanguages", "(ja)",
            "-AppleLocale", "ja_JP",
        ]
        app.launch()

        let question = app.staticTexts["reflection-question"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10))

        app.buttons["閉じる"].firstMatch.tap()
        XCTAssertTrue(question.waitForNonExistence(timeout: 5))
    }
}
