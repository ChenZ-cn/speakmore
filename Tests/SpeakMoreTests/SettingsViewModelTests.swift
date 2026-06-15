import XCTest
@testable import SpeakMore

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testSavePersistsEditableSettingsAndAPIKey() throws {
        let store = InMemorySettingsStore()
        let keychain = CapturingAPIKeyStore()
        let model = SettingsViewModel(settingsStore: store, apiKeyStore: keychain)

        model.speechAPIKey = "test-speech-key"
        model.speechRecognitionProviderKind = .customOpenAIRealtime
        model.speechRecognitionModel = "custom-whisper"
        model.speechRecognitionEndpoint = "wss://speech.example.com/realtime?intent=transcription"
        model.textAPIKey = "test-text-key"
        model.textAIProviderKind = .deepSeek
        model.textAIModel = "deepseek-v4-flash"
        model.textAIEndpoint = "https://api.deepseek.com/chat/completions"
        model.defaultMode = .translate
        model.targetLanguage = "Spanish"
        model.isHistoryEnabled = true
        model.interfaceLanguage = .english
        model.textPolishIntensity = .strong
        model.voiceInputShortcut = VoiceInputShortcut(
            trigger: .toggle,
            binding: .init(modifiers: [.control, .option], keyCode: 49, charactersIgnoringModifiers: " ")
        )

        try model.save()

        XCTAssertEqual(keychain.savedAPIKeysByAccount["speech-custom"], "test-speech-key")
        XCTAssertEqual(keychain.savedAPIKeysByAccount["deepseek"], "test-text-key")
        XCTAssertEqual(store.speechRecognitionProviderKind, .customOpenAIRealtime)
        XCTAssertEqual(store.speechRecognitionModel, "custom-whisper")
        XCTAssertEqual(store.speechRecognitionEndpoint, "wss://speech.example.com/realtime?intent=transcription")
        XCTAssertEqual(store.textAIProviderKind, .deepSeek)
        XCTAssertEqual(store.textAIModel, "deepseek-v4-flash")
        XCTAssertEqual(store.textAIEndpoint, "https://api.deepseek.com/chat/completions")
        XCTAssertEqual(store.defaultMode, .translate)
        XCTAssertEqual(store.targetLanguage, "Spanish")
        XCTAssertTrue(store.isHistoryEnabled)
        XCTAssertEqual(store.interfaceLanguage, .english)
        XCTAssertEqual(store.textPolishIntensity, .strong)
        XCTAssertEqual(
            store.voiceInputShortcut,
            VoiceInputShortcut(
                trigger: .toggle,
                binding: .init(modifiers: [.control, .option], keyCode: 49, charactersIgnoringModifiers: " ")
            )
        )
        XCTAssertEqual(model.saveStatus, "Saved")
    }

    func testSaveTrimsAPIKeyAndSkipsEmptyKeychainWrite() throws {
        let keychain = CapturingAPIKeyStore()
        let model = SettingsViewModel(settingsStore: InMemorySettingsStore(), apiKeyStore: keychain)

        model.speechAPIKey = "   \n"
        model.textAPIKey = "   \n"

        try model.save()

        XCTAssertEqual(keychain.savedAPIKeysByAccount, [:])
        XCTAssertEqual(model.saveStatus, "已保存")
    }

    func testSaveStatusUsesSelectedInterfaceLanguage() throws {
        let model = SettingsViewModel(settingsStore: InMemorySettingsStore(), apiKeyStore: CapturingAPIKeyStore())

        model.interfaceLanguage = .english

        try model.save()

        XCTAssertEqual(model.saveStatus, "Saved")
    }

    func testSaveReportsKeychainError() {
        let keychain = CapturingAPIKeyStore(saveError: KeychainError.unhandled(errSecAuthFailed))
        let model = SettingsViewModel(settingsStore: InMemorySettingsStore(), apiKeyStore: keychain)
        model.speechAPIKey = "test-api-key"

        XCTAssertThrowsError(try model.save())
        XCTAssertEqual(model.saveStatus, "无法保存语音 API Key")
    }

    func testRefreshFromStoreLoadsCurrentSettings() {
        let store = InMemorySettingsStore()
        let keychain = CapturingAPIKeyStore(apiKeys: [
            "aliyun-bailian": "test-speech-live",
            "deepseek": "test-text-live"
        ])
        let model = SettingsViewModel(settingsStore: store, apiKeyStore: keychain)

        store.defaultMode = .translate
        store.targetLanguage = "French"
        store.isHistoryEnabled = true
        store.interfaceLanguage = .french
        store.textPolishIntensity = .light
        store.voiceInputShortcut = VoiceInputShortcut(
            trigger: .pressAndHold,
            binding: .init(modifiers: [.control, .shift], keyCode: nil, charactersIgnoringModifiers: nil)
        )
        store.textAIProviderKind = .deepSeek
        store.textAIModel = "deepseek-v4-flash"
        store.textAIEndpoint = "https://api.deepseek.com/chat/completions"

        model.refreshFromStore()

        XCTAssertEqual(model.speechAPIKey, "test-speech-live")
        XCTAssertEqual(model.textAPIKey, "test-text-live")
        XCTAssertEqual(model.defaultMode, .translate)
        XCTAssertEqual(model.targetLanguage, "French")
        XCTAssertTrue(model.isHistoryEnabled)
        XCTAssertEqual(model.interfaceLanguage, .french)
        XCTAssertEqual(model.textPolishIntensity, .light)
        XCTAssertEqual(
            model.voiceInputShortcut,
            VoiceInputShortcut(
                trigger: .pressAndHold,
                binding: .init(modifiers: [.control, .shift], keyCode: nil, charactersIgnoringModifiers: nil)
            )
        )
        XCTAssertEqual(model.textAIProviderKind, .deepSeek)
        XCTAssertEqual(model.textAIModel, "deepseek-v4-flash")
        XCTAssertEqual(model.textAIEndpoint, "https://api.deepseek.com/chat/completions")
    }

    func testSelectingProvidersAppliesDefaultEndpointAndModel() {
        let model = SettingsViewModel(settingsStore: InMemorySettingsStore(), apiKeyStore: CapturingAPIKeyStore())

        model.selectSpeechRecognitionProvider(.aliyunBailianRealtime)
        model.selectTextAIProvider(.siliconFlow)

        XCTAssertEqual(model.speechRecognitionModel, "qwen3-asr-flash-realtime-2026-02-10")
        XCTAssertEqual(model.speechRecognitionEndpoint, "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime-2026-02-10")
        XCTAssertEqual(model.textAIModel, "deepseek-ai/DeepSeek-V4-Flash")
        XCTAssertEqual(model.textAIEndpoint, "https://api.siliconflow.cn/v1/chat/completions")
    }

    func testRefreshFromStoreReportsSetupNeededWhenKeysAreMissing() {
        let model = SettingsViewModel(settingsStore: InMemorySettingsStore(), apiKeyStore: CapturingAPIKeyStore())

        model.refreshFromStore()

        XCTAssertTrue(model.needsAPISetup)
    }

    func testRefreshFromStoreReportsSetupCompleteWhenKeysExist() {
        let keychain = CapturingAPIKeyStore(apiKeys: [
            "aliyun-bailian": "aliyun-key",
            "siliconflow": "silicon-key"
        ])
        let model = SettingsViewModel(settingsStore: InMemorySettingsStore(), apiKeyStore: keychain)

        model.refreshFromStore()

        XCTAssertFalse(model.needsAPISetup)
    }

    func testSaveDoesNotOverwriteExternallyChangedModeWhenModelIsStale() throws {
        let store = InMemorySettingsStore()
        let model = SettingsViewModel(settingsStore: store, apiKeyStore: CapturingAPIKeyStore())

        store.defaultMode = .askSelectedText
        model.targetLanguage = "German"

        try model.save()

        XCTAssertEqual(store.defaultMode, .askSelectedText)
        XCTAssertEqual(store.targetLanguage, "German")
        XCTAssertEqual(model.defaultMode, .askSelectedText)
    }

    func testSaveCallsOnSavedAfterSuccessfulSave() throws {
        let model = SettingsViewModel(settingsStore: InMemorySettingsStore(), apiKeyStore: CapturingAPIKeyStore())
        var saveCount = 0
        model.onSaved = {
            saveCount += 1
        }

        try model.save()

        XCTAssertEqual(saveCount, 1)
    }

    func testOpenTutorialCallsTutorialHandler() {
        var openCount = 0
        let model = SettingsViewModel(
            settingsStore: InMemorySettingsStore(),
            apiKeyStore: CapturingAPIKeyStore(),
            onOpenTutorial: {
                openCount += 1
            }
        )

        model.openTutorial()

        XCTAssertEqual(openCount, 1)
    }
}

private final class InMemorySettingsStore: SettingsStore {
    var defaultMode: SpeakMoreMode = .auto
    var targetLanguage: String = "English"
    var isHistoryEnabled = false
    var launchAtLogin = false
    var interfaceLanguage: AppLanguage = .system
    var textPolishIntensity: TextPolishIntensity = .medium
    var voiceInputShortcut: VoiceInputShortcut = .default
    var speechRecognitionProviderKind: SpeechRecognitionProviderKind = .aliyunBailianRealtime
    var speechRecognitionModel: String = "qwen3-asr-flash-realtime-2026-02-10"
    var speechRecognitionEndpoint: String = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime-2026-02-10"
    var textAIProviderKind: TextAIProviderKind = .aliyunBailian
    var textAIModel: String = "qwen3.6-flash"
    var textAIEndpoint: String = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
}

private final class CapturingAPIKeyStore: APIKeyStore {
    private let saveError: Error?
    private let apiKeys: [String: String]
    private(set) var savedAPIKeysByAccount: [String: String] = [:]

    init(apiKeys: [String: String] = [:], saveError: Error? = nil) {
        self.apiKeys = apiKeys
        self.saveError = saveError
    }

    func readAPIKey(account: String) -> String? {
        apiKeys[account]
    }

    func saveAPIKey(_ apiKey: String, account: String) throws {
        if let saveError {
            throw saveError
        }
        savedAPIKeysByAccount[account] = apiKey
    }
}
