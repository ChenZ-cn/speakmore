import XCTest

final class PackageIdentityTests: XCTestCase {
    func testSwiftPackageUsesSpeakMoreIdentity() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let package = try String(contentsOf: root.appendingPathComponent("Package.swift"), encoding: .utf8)

        XCTAssertTrue(package.contains(#"name: "SpeakMore""#))
        XCTAssertTrue(package.contains(#".executable(name: "SpeakMore", targets: ["SpeakMore"])"#))
        XCTAssertTrue(package.contains(#"name: "SpeakMore","#))
        XCTAssertTrue(package.contains(#"path: "Sources/SpeakMore""#))
        XCTAssertTrue(package.contains(#"name: "SpeakMoreTests","#))
        XCTAssertTrue(package.contains(#"dependencies: ["SpeakMore"]"#))
        XCTAssertTrue(package.contains(#"path: "Tests/SpeakMoreTests""#))
    }

    func testDevelopmentCommandsUseSpeakMoreExecutable() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let readme = try String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)
        let buildScript = try String(contentsOf: root.appendingPathComponent("Scripts/build_app.sh"), encoding: .utf8)

        XCTAssertTrue(readme.contains("swift run SpeakMore"))
        XCTAssertTrue(readme.contains(#"open "build/SpeakMore-多说有益.app""#))
        XCTAssertFalse(readme.contains("swift run Typeless"))
        XCTAssertTrue(buildScript.contains(#".build/$CONFIGURATION/SpeakMore"#))
        XCTAssertFalse(buildScript.contains(#".build/$CONFIGURATION/Typeless"#))
    }
}
