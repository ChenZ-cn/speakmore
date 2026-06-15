import XCTest

final class AppBundleBrandingTests: XCTestCase {
    func testInfoPlistUsesSpeakMoreBilingualDisplayNameAndIcon() throws {
        let root = try repositoryRoot()
        let plistURL = root.appendingPathComponent("Resources/Info.plist")
        let data = try Data(contentsOf: plistURL)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        XCTAssertEqual(plist["CFBundleName"] as? String, "SpeakMore-多说有益")
        XCTAssertEqual(plist["CFBundleDisplayName"] as? String, "SpeakMore-多说有益")
        XCTAssertEqual(plist["CFBundleIconFile"] as? String, "AppIcon")
    }

    func testChineseLocalizedBundleNameDoesNotHideSpeakMore() throws {
        let root = try repositoryRoot()
        let strings = try String(
            contentsOf: root.appendingPathComponent("Resources/zh-Hans.lproj/InfoPlist.strings"),
            encoding: .utf8
        )

        XCTAssertTrue(strings.contains(#"CFBundleName = "SpeakMore-多说有益";"#))
        XCTAssertTrue(strings.contains(#"CFBundleDisplayName = "SpeakMore-多说有益";"#))
    }

    func testBuildScriptBundlesAppIconAndNamesAppBundle() throws {
        let root = try repositoryRoot()
        let script = try String(
            contentsOf: root.appendingPathComponent("Scripts/build_app.sh"),
            encoding: .utf8
        )

        XCTAssertTrue(script.contains("SpeakMore-多说有益.app"))
        XCTAssertTrue(script.contains("AppIcon.icns"))
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
        throw NSError(domain: "AppBundleBrandingTests", code: 1)
    }
}
