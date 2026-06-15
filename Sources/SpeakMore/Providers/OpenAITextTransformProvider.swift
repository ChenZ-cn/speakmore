import Foundation

final class OpenAITextTransformProvider {
    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let promptBuilder: TextTransformPromptBuilder
    private let session: URLSession
    private let providerName: String
    private let extraRequestBody: [String: Any]

    init(
        apiKey: String,
        model: String = "gpt-5.4-nano",
        endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
        providerName: String = "OpenAI",
        extraRequestBody: [String: Any] = [:],
        promptBuilder: TextTransformPromptBuilder = TextTransformPromptBuilder(),
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.providerName = providerName
        self.extraRequestBody = extraRequestBody
        self.promptBuilder = promptBuilder
        self.session = session
    }

    func makeRequestBody(input: VoiceSessionInput) throws -> Data {
        let prompt = promptBuilder.build(input: input)
        var payload: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": prompt.system],
                ["role": "user", "content": prompt.user]
            ]
        ]
        payload[tokenLimitParameterName] = 600
        for (key, value) in extraRequestBody {
            payload[key] = value
        }
        return try JSONSerialization.data(withJSONObject: payload)
    }

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeRequestBody(input: input)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAITextTransformError.httpStatus(-1, message: nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw makeHTTPError(statusCode: http.statusCode, data: data)
        }

        let text = try parseResponse(data)
        return VoiceSessionResult(
            rawTranscript: input.rawTranscript,
            finalText: text,
            shouldReplaceSelection: input.mode == .askSelectedText
        )
    }

    func parseResponse(_ data: Data) throws -> String {
        let decoded: ChatCompletionResponse
        do {
            decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw OpenAITextTransformError.decodingFailed(error.localizedDescription)
        }
        let text = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty {
            throw OpenAITextTransformError.emptyResponse
        }
        return text
    }

    func makeHTTPError(statusCode: Int, data: Data) -> OpenAITextTransformError {
        let message = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data).error.message
        return .httpStatus(statusCode, message: message?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty)
    }

    private var tokenLimitParameterName: String {
        if providerName == "OpenAI" || endpoint.host?.localizedCaseInsensitiveContains("api.openai.com") == true {
            return "max_completion_tokens"
        }

        return "max_tokens"
    }
}

extension OpenAITextTransformProvider: TextTransformProvider {}

enum OpenAITextTransformError: LocalizedError {
    case httpStatus(Int, message: String?)
    case emptyResponse
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case let .httpStatus(statusCode, message):
            if let message {
                return "OpenAI request failed with HTTP \(statusCode): \(message)"
            }
            return "OpenAI request failed with HTTP \(statusCode)"
        case .emptyResponse:
            return "OpenAI returned an empty text response."
        case let .decodingFailed(message):
            return "OpenAI returned an unreadable text response: \(message)"
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct OpenAIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}
