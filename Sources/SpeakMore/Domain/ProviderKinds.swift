import Foundation

enum SpeechRecognitionProviderKind: String, CaseIterable, Codable, Equatable {
    case aliyunBailianRealtime
    case openAIRealtime
    case customOpenAIRealtime

    var title: String {
        switch self {
        case .aliyunBailianRealtime: "阿里云百炼实时"
        case .openAIRealtime: "OpenAI 实时"
        case .customOpenAIRealtime: "自定义实时"
        }
    }

    var defaultModel: String {
        switch self {
        case .aliyunBailianRealtime:
            "qwen3-asr-flash-realtime-2026-02-10"
        case .openAIRealtime, .customOpenAIRealtime:
            "gpt-realtime-whisper"
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .aliyunBailianRealtime:
            "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime-2026-02-10"
        case .openAIRealtime, .customOpenAIRealtime:
            "wss://api.openai.com/v1/realtime?intent=transcription"
        }
    }

    var apiKeyAccount: String {
        switch self {
        case .aliyunBailianRealtime: "aliyun-bailian"
        case .openAIRealtime: "openai"
        case .customOpenAIRealtime: "speech-custom"
        }
    }

    var apiKeyAccounts: [String] {
        switch self {
        case .aliyunBailianRealtime: ["aliyun-bailian", "aliyun"]
        case .openAIRealtime: ["openai", "openai-backup"]
        case .customOpenAIRealtime: ["speech-custom"]
        }
    }
}

enum TextAIProviderKind: String, CaseIterable, Codable, Equatable {
    case siliconFlow
    case aliyunBailian
    case openAI
    case deepSeek
    case custom

    var title: String {
        switch self {
        case .siliconFlow: "硅基流动"
        case .aliyunBailian: "阿里云百炼"
        case .openAI: "OpenAI"
        case .deepSeek: "DeepSeek"
        case .custom: "自定义"
        }
    }

    var defaultModel: String {
        switch self {
        case .siliconFlow: "deepseek-ai/DeepSeek-V4-Flash"
        case .aliyunBailian: "qwen3.6-flash"
        case .openAI: "gpt-5.4-nano"
        case .deepSeek: "deepseek-v4-flash"
        case .custom: "gpt-5.4-nano"
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .siliconFlow: "https://api.siliconflow.cn/v1/chat/completions"
        case .aliyunBailian: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
        case .openAI, .custom: "https://api.openai.com/v1/chat/completions"
        case .deepSeek: "https://api.deepseek.com/chat/completions"
        }
    }

    var apiKeyAccount: String {
        switch self {
        case .siliconFlow: "siliconflow"
        case .aliyunBailian: "aliyun-bailian"
        case .openAI: "text-openai"
        case .deepSeek: "deepseek"
        case .custom: "text-custom"
        }
    }

    var apiKeyAccounts: [String] {
        switch self {
        case .siliconFlow: ["siliconflow", "text-custom"]
        case .aliyunBailian: ["aliyun-bailian", "aliyun"]
        case .openAI: ["text-openai", "openai", "openai-backup"]
        case .deepSeek: ["deepseek"]
        case .custom: ["text-custom"]
        }
    }

    var extraRequestBody: [String: Any] {
        switch self {
        case .aliyunBailian:
            ["enable_thinking": false]
        case .deepSeek:
            ["thinking": ["type": "disabled"]]
        case .siliconFlow, .openAI, .custom:
            [:]
        }
    }

    static func chatCompletionsEndpoint(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard var components = URLComponents(string: trimmed) else {
            return nil
        }

        if components.path.hasSuffix("/chat/completions") {
            return components.url
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if basePath.isEmpty {
            components.path = "/chat/completions"
        } else {
            components.path = "/" + basePath + "/chat/completions"
        }
        return components.url
    }
}
