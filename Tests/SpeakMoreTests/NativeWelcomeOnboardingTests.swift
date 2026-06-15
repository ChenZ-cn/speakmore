import XCTest

final class NativeWelcomeOnboardingTests: XCTestCase {
    func testWelcomeOnboardingDoesNotDependOnWebView() throws {
        let root = try repositoryRoot()
        let controllerSource = try String(
            contentsOf: root
                .appendingPathComponent("Sources/SpeakMore/UI/WelcomeOnboardingWindowController.swift"),
            encoding: .utf8
        )
        let packageSource = try String(
            contentsOf: root.appendingPathComponent("Package.swift"),
            encoding: .utf8
        )

        XCTAssertFalse(controllerSource.contains("import WebKit"))
        XCTAssertFalse(controllerSource.contains("WKWebView"))
        XCTAssertFalse(packageSource.contains(".linkedFramework(\"WebKit\")"))
    }

    func testWelcomeWindowUsesFixedNonResizableContentSize() throws {
        let root = try repositoryRoot()
        let controllerSource = try String(
            contentsOf: root
                .appendingPathComponent("Sources/SpeakMore/UI/WelcomeOnboardingWindowController.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(controllerSource.contains("contentRect: NSRect(x: 0, y: 0, width: 1080, height: 716)"))
        XCTAssertTrue(controllerSource.contains("styleMask: [.titled, .closable, .miniaturizable]"))
        XCTAssertTrue(controllerSource.contains("window.contentMinSize = NSSize(width: 1080, height: 716)"))
        XCTAssertTrue(controllerSource.contains("window.contentMaxSize = NSSize(width: 1080, height: 716)"))
        XCTAssertTrue(controllerSource.contains("window.standardWindowButton(.zoomButton)?.isEnabled = false"))
        XCTAssertFalse(controllerSource.contains(".resizable"))
        XCTAssertFalse(controllerSource.contains(".fullSizeContentView"))
        XCTAssertFalse(controllerSource.contains("contentAspectRatio"))
        XCTAssertFalse(controllerSource.contains("titlebarAppearsTransparent = true"))
    }

    func testBuildDoesNotBundlePrototypeHtmlForWelcomeFlow() throws {
        let root = try repositoryRoot()
        let buildScript = try String(
            contentsOf: root.appendingPathComponent("Scripts/build_app.sh"),
            encoding: .utf8
        )

        XCTAssertFalse(buildScript.contains("prototypes/welcome-home"))
        XCTAssertFalse(buildScript.contains("prototypes/welcome-onboarding"))
        XCTAssertFalse(buildScript.contains("Resources/Welcome"))
    }

    func testNativeWelcomeCopyKeepsApprovedTrialAllowance() throws {
        let root = try repositoryRoot()
        let nativeSource = try String(
            contentsOf: root
                .appendingPathComponent("Sources/SpeakMore/UI/WelcomeOnboardingView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(nativeSource.contains(#"Text("Speak ")"#))
        XCTAssertTrue(nativeSource.contains(#"Text("More")"#))
        XCTAssertTrue(nativeSource.contains("多说有益，用说话完成输入。"))
        XCTAssertTrue(nativeSource.contains("2000 字输出"))
        XCTAssertTrue(nativeSource.contains("10 分钟语音识别"))
    }

    func testNativeWelcomeKeepsWebPrototypeFlowShape() throws {
        let root = try repositoryRoot()
        let nativeSource = try String(
            contentsOf: root
                .appendingPathComponent("Sources/SpeakMore/UI/WelcomeOnboardingView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(nativeSource.contains("WelcomeLanguagePicker"))
        XCTAssertTrue(nativeSource.contains("稍后再说"))
        XCTAssertTrue(nativeSource.contains("开始配置"))
        XCTAssertTrue(nativeSource.contains("bar active"))
        XCTAssertFalse(nativeSource.contains("case language"))
        XCTAssertFalse(nativeSource.contains("id: \"language\""))
    }

    func testNativeWelcomeUsesFixedCanvasWithoutInternalWindowChromeOrScaling() throws {
        let root = try repositoryRoot()
        let nativeSource = try String(
            contentsOf: root
                .appendingPathComponent("Sources/SpeakMore/UI/WelcomeOnboardingView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(nativeSource.contains("OnboardingCanvas(width: 1080, height: 716)"))
        XCTAssertTrue(nativeSource.contains(".frame(width: 1080, height: 716)"))
        XCTAssertFalse(nativeSource.contains("ScaledPrototypeHost"))
        XCTAssertFalse(nativeSource.contains("scaleEffect(scale)"))
        XCTAssertFalse(nativeSource.contains("availableWidth / baseWidth"))
        XCTAssertFalse(nativeSource.contains("GeometryReader"))
        XCTAssertFalse(nativeSource.contains("PrototypeTitlebar"))
        XCTAssertFalse(nativeSource.contains("PrototypeWindow(width: 1024"))
        XCTAssertFalse(nativeSource.contains("min(1, min(availableWidth / baseWidth, availableHeight / baseHeight))"))
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
        throw NSError(domain: "NativeWelcomeOnboardingTests", code: 1)
    }
}
