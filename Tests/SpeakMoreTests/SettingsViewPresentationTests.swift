import XCTest

final class SettingsViewPresentationTests: XCTestCase {
    func testSettingsViewExposesTutorialSectionAndUsesLeftAlignedRows() throws {
        let root = try repositoryRoot()
        let source = try String(
            contentsOf: root.appendingPathComponent("Sources/SpeakMore/UI/SettingsView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("settingsSection(strings.tutorial"))
        XCTAssertTrue(source.contains("model.openTutorial()"))
        XCTAssertTrue(source.contains(".frame(width: 86, alignment: .leading)"))
        XCTAssertFalse(source.contains(".frame(width: 86, alignment: .trailing)"))
    }

    func testSettingsSaveClosesWindowAndTutorialActionReopensWelcome() throws {
        let root = try repositoryRoot()
        let source = try String(
            contentsOf: root.appendingPathComponent("Sources/SpeakMore/App/AppDelegate.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("self?.settingsWindowController?.window?.close()"))
        XCTAssertTrue(source.contains("onOpenTutorial: { [weak self] in"))
        XCTAssertTrue(source.contains("self?.showWelcomeOnboardingWindow()"))
    }

    private func repositoryRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.path != "/" {
            let candidate = url.appendingPathComponent("Package.swift")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return url
            }
            url.deleteLastPathComponent()
        }
        throw NSError(domain: "SettingsViewPresentationTests", code: 1)
    }
}
