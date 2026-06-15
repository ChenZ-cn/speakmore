import XCTest
@testable import SpeakMore

final class ProviderConfigurationTests: XCTestCase {
    func testTextAIProviderDefaultsAreOpenSourceFriendly() {
        XCTAssertEqual(TextAIProviderKind.siliconFlow.defaultModel, "deepseek-ai/DeepSeek-V4-Flash")
        XCTAssertEqual(TextAIProviderKind.siliconFlow.defaultEndpoint, "https://api.siliconflow.cn/v1/chat/completions")
        XCTAssertEqual(TextAIProviderKind.aliyunBailian.defaultModel, "qwen3.6-flash")
        XCTAssertEqual(TextAIProviderKind.aliyunBailian.defaultEndpoint, "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")
        XCTAssertEqual(TextAIProviderKind.aliyunBailian.extraRequestBody["enable_thinking"] as? Bool, false)
        XCTAssertEqual(TextAIProviderKind.deepSeek.defaultModel, "deepseek-v4-flash")
        XCTAssertEqual(TextAIProviderKind.deepSeek.defaultEndpoint, "https://api.deepseek.com/chat/completions")
    }

    func testSpeechProviderExposesEndpointModelAndKeyAccount() {
        XCTAssertEqual(SpeechRecognitionProviderKind.aliyunBailianRealtime.defaultModel, "qwen3-asr-flash-realtime-2026-02-10")
        XCTAssertEqual(
            SpeechRecognitionProviderKind.aliyunBailianRealtime.defaultEndpoint,
            "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime-2026-02-10"
        )
        XCTAssertEqual(SpeechRecognitionProviderKind.aliyunBailianRealtime.apiKeyAccount, "aliyun-bailian")
        XCTAssertEqual(SpeechRecognitionProviderKind.openAIRealtime.defaultModel, "gpt-realtime-whisper")
        XCTAssertEqual(SpeechRecognitionProviderKind.customOpenAIRealtime.apiKeyAccount, "speech-custom")
    }

    func testChatCompletionsEndpointAddsPathToBaseURL() {
        XCTAssertEqual(
            TextAIProviderKind.chatCompletionsEndpoint(from: "https://api.deepseek.com")?.absoluteString,
            "https://api.deepseek.com/chat/completions"
        )
        XCTAssertEqual(
            TextAIProviderKind.chatCompletionsEndpoint(from: "https://example.com/v1/chat/completions")?.absoluteString,
            "https://example.com/v1/chat/completions"
        )
    }

    func testProviderMenuTitlesUseSelectedInterfaceLanguage() {
        let englishStrings = AppInterfaceStrings(language: .english)
        let chineseStrings = AppInterfaceStrings(language: .simplifiedChinese)

        XCTAssertEqual(englishStrings.speechRecognitionProviderTitle(.aliyunBailianRealtime), "Alibaba Bailian Realtime")
        XCTAssertEqual(englishStrings.speechRecognitionProviderTitle(.customOpenAIRealtime), "Custom Realtime")
        XCTAssertEqual(englishStrings.textAIProviderTitle(.siliconFlow), "SiliconFlow")
        XCTAssertEqual(englishStrings.textAIProviderTitle(.aliyunBailian), "Alibaba Bailian")
        XCTAssertEqual(englishStrings.textAIProviderTitle(.custom), "Custom")
        XCTAssertEqual(chineseStrings.textAIProviderTitle(.custom), "自定义")
    }
}
