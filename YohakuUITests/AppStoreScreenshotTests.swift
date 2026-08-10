import XCTest

/// Generates App Store and brand-site screenshots for every localization the
/// app ships. Navigation goes through accessibility identifiers only, so the
/// same run works in Arabic and Thai without a table of translated button
/// labels; demo data comes from the localized `name.pool.N` catalog.
final class AppStoreScreenshotTests: XCTestCase {
    /// (language, locale) for each of the 18 String Catalog localizations.
    private static let localizations: [(language: String, locale: String)] = [
        ("ar", "ar_SA"),
        ("de", "de_DE"),
        ("en", "en_US"),
        ("es", "es_ES"),
        ("fr", "fr_FR"),
        ("hi", "hi_IN"),
        ("id", "id_ID"),
        ("it", "it_IT"),
        ("ja", "ja_JP"),
        ("ko", "ko_KR"),
        ("nl", "nl_NL"),
        ("pl", "pl_PL"),
        ("pt-BR", "pt_BR"),
        ("th", "th_TH"),
        ("tr", "tr_TR"),
        ("vi", "vi_VN"),
        ("zh-Hans", "zh_CN"),
        ("zh-Hant", "zh_TW"),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLocalizedScreenshots() throws {
        for localization in Self.localizations {
            try captureScreenshots(localization)
            try captureReflection(localization)
            try captureDarkHome(localization)
        }
    }

    private func launch(
        _ localization: (language: String, locale: String),
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ScreenshotMode",
            "-AppleLanguages", "(\(localization.language))",
            "-AppleLocale", localization.locale,
        ] + extraArguments
        app.launch()
        return app
    }

    private func captureScreenshots(_ localization: (language: String, locale: String)) throws {
        let prefix = localization.language
        let app = launch(localization)
        defer { app.terminate() }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "no tab bar in \(prefix)")
        addScreenshot("\(prefix)-01-today", app: app)

        tabBar.buttons.element(boundBy: 1).tap()
        addScreenshot("\(prefix)-02-week", app: app)

        tabBar.buttons.element(boundBy: 2).tap()
        addScreenshot("\(prefix)-03-month", app: app)

        let settingsButton = app.buttons["settings-button"].firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "no settings button in \(prefix)")
        settingsButton.tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10))
        sleep(1)
        addScreenshot("\(prefix)-04-settings-iap", app: app)

        app.buttons["close-button"].firstMatch.tap()

        // The add sheet is only reachable from Today.
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        tabBar.buttons.element(boundBy: 0).tap()

        let addButton = app.buttons["add-button"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "no add button in \(prefix)")
        addButton.tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10))

        // An empty name leaves the sheet with the keyboard up and the place
        // button disabled — a true screen, but not one worth showing. Take a
        // suggested name and dismiss the keyboard so the sheet is complete.
        let suggestion = app.buttons["suggestion-0"].firstMatch
        if suggestion.waitForExistence(timeout: 10) {
            suggestion.tap()
        }
        if app.keyboards.element.waitForExistence(timeout: 5) {
            app.typeText("\n")
            _ = app.keyboards.element.waitForNonExistence(timeout: 5)
        }
        sleep(1)
        addScreenshot("\(prefix)-05-add", app: app)
    }

    private func captureReflection(_ localization: (language: String, locale: String)) throws {
        let prefix = localization.language
        let app = launch(localization, extraArguments: ["-ReflectionPreview"])
        defer { app.terminate() }

        let question = app.staticTexts["reflection-question"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 20), "no reflection card in \(prefix)")
        sleep(1)
        addScreenshot("\(prefix)-06-reflection", app: app)
    }

    private func captureDarkHome(_ localization: (language: String, locale: String)) throws {
        let prefix = localization.language
        let app = launch(localization, extraArguments: ["-appearanceMode", "dark"])
        defer { app.terminate() }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "no dark home in \(prefix)")
        sleep(1)
        addScreenshot("\(prefix)-07-today-dark", app: app)
    }

    private func addScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
