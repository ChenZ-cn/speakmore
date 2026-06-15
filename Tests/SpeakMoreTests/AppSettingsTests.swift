import XCTest
@testable import SpeakMore

final class AppSettingsTests: XCTestCase {
    func testDefaultsMatchMVPPrivacyDecisions() {
        let defaults = UserDefaults(suiteName: "SpeakMoreTests.defaults")!
        defaults.removePersistentDomain(forName: "SpeakMoreTests.defaults")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.defaultMode, .auto)
        XCTAssertEqual(settings.targetLanguage, "English")
        XCTAssertFalse(settings.isHistoryEnabled)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.hasSeenWelcomeOnboarding)
        XCTAssertEqual(settings.interfaceLanguage, .system)
        XCTAssertEqual(settings.textPolishIntensity, .medium)
        XCTAssertEqual(settings.voiceInputShortcut, .default)
        XCTAssertEqual(settings.speechRecognitionProviderKind, .aliyunBailianRealtime)
        XCTAssertEqual(settings.speechRecognitionModel, "qwen3-asr-flash-realtime-2026-02-10")
        XCTAssertEqual(settings.speechRecognitionEndpoint, "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime-2026-02-10")
        XCTAssertEqual(settings.textAIProviderKind, .aliyunBailian)
        XCTAssertEqual(settings.textAIModel, "qwen3.6-flash")
        XCTAssertEqual(settings.textAIEndpoint, "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")
    }

    func testSettingsPersist() {
        let defaults = UserDefaults(suiteName: "SpeakMoreTests.persist")!
        defaults.removePersistentDomain(forName: "SpeakMoreTests.persist")
        let settings = AppSettings(defaults: defaults)

        settings.defaultMode = .translate
        settings.targetLanguage = "Japanese"
        settings.isHistoryEnabled = true
        settings.launchAtLogin = true
        settings.hasSeenWelcomeOnboarding = true
        settings.interfaceLanguage = .english
        settings.textPolishIntensity = .strong
        settings.voiceInputShortcut = VoiceInputShortcut(
            trigger: .toggle,
            binding: .init(modifiers: [.control, .option], keyCode: 49, charactersIgnoringModifiers: " ")
        )
        settings.textAIProviderKind = .deepSeek
        settings.textAIModel = "deepseek-v4-flash"
        settings.textAIEndpoint = "https://api.deepseek.com/chat/completions"

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.defaultMode, .translate)
        XCTAssertEqual(reloaded.targetLanguage, "Japanese")
        XCTAssertTrue(reloaded.isHistoryEnabled)
        XCTAssertTrue(reloaded.launchAtLogin)
        XCTAssertTrue(reloaded.hasSeenWelcomeOnboarding)
        XCTAssertEqual(reloaded.interfaceLanguage, .english)
        XCTAssertEqual(reloaded.textPolishIntensity, .strong)
        XCTAssertEqual(
            reloaded.voiceInputShortcut,
            VoiceInputShortcut(
                trigger: .toggle,
                binding: .init(modifiers: [.control, .option], keyCode: 49, charactersIgnoringModifiers: " ")
            )
        )
        XCTAssertEqual(reloaded.textAIProviderKind, .deepSeek)
        XCTAssertEqual(reloaded.textAIModel, "deepseek-v4-flash")
        XCTAssertEqual(reloaded.textAIEndpoint, "https://api.deepseek.com/chat/completions")
    }
}
