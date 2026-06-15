import XCTest
@testable import SpeakMore

final class OpenAITextTransformProviderTests: XCTestCase {
    func testRequestBodyContainsModelAndMessages() throws {
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "hello there",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let provider = OpenAITextTransformProvider(apiKey: "test-key")
        let body = try provider.makeRequestBody(input: input)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let messages = try XCTUnwrap(object["messages"] as? [[String: String]])

        XCTAssertEqual(object["model"] as? String, "gpt-5.4-nano")
        XCTAssertEqual(object["max_completion_tokens"] as? Int, 600)
        XCTAssertNil(object["max_tokens"])
        XCTAssertTrue(messages.contains { $0["content"]?.contains("hello there") == true })
    }

    func testCustomCompatibleEndpointUsesMaxTokens() throws {
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "hello there",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )
        let provider = OpenAITextTransformProvider(
            apiKey: "test-key",
            endpoint: URL(string: "https://api.siliconflow.cn/v1/chat/completions")!,
            providerName: "Custom"
        )

        let body = try provider.makeRequestBody(input: input)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(object["max_tokens"] as? Int, 600)
        XCTAssertNil(object["max_completion_tokens"])
    }

    func testRequestBodyCanIncludeProviderSpecificExtraBody() throws {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "整理一下这个句子",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )
        let provider = OpenAITextTransformProvider(
            apiKey: "test-key",
            model: "deepseek-v4-flash",
            providerName: "DeepSeek",
            extraRequestBody: ["thinking": ["type": "disabled"]]
        )

        let body = try provider.makeRequestBody(input: input)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let thinking = try XCTUnwrap(object["thinking"] as? [String: String])

        XCTAssertEqual(object["model"] as? String, "deepseek-v4-flash")
        XCTAssertEqual(thinking["type"], "disabled")
    }

    func testParseResponseReturnsTrimmedMessageContent() throws {
        let provider = OpenAITextTransformProvider(apiKey: "test-key")
        let data = Data("""
        {
            "choices": [
                {
                    "message": {
                        "content": "  cleaned text\\n"
                    }
                }
            ]
        }
        """.utf8)

        let text = try provider.parseResponse(data)

        XCTAssertEqual(text, "cleaned text")
    }

    func testParseResponseThrowsForEmptyMessageContent() throws {
        let provider = OpenAITextTransformProvider(apiKey: "test-key")
        let data = Data("""
        {
            "choices": [
                {
                    "message": {
                        "content": "   "
                    }
                }
            ]
        }
        """.utf8)

        XCTAssertThrowsError(try provider.parseResponse(data)) { error in
            XCTAssertTrue(error is OpenAITextTransformError)
        }
    }

    func testMakeHTTPErrorIncludes401StatusAndOpenAIMessage() {
        let provider = OpenAITextTransformProvider(apiKey: "test-key")
        let data = Data("""
        {
            "error": {
                "message": "Incorrect API key provided",
                "type": "invalid_request_error",
                "code": "invalid_api_key"
            }
        }
        """.utf8)

        let error = provider.makeHTTPError(statusCode: 401, data: data)

        XCTAssertEqual(error.localizedDescription, "OpenAI request failed with HTTP 401: Incorrect API key provided")
    }

    func testMakeHTTPErrorIncludes429StatusAndOpenAIMessage() {
        let provider = OpenAITextTransformProvider(apiKey: "test-key")
        let data = Data("""
        {
            "error": {
                "message": "Rate limit reached for requests",
                "type": "rate_limit_error",
                "code": null
            }
        }
        """.utf8)

        let error = provider.makeHTTPError(statusCode: 429, data: data)

        XCTAssertEqual(error.localizedDescription, "OpenAI request failed with HTTP 429: Rate limit reached for requests")
    }

    func testMakeHTTPErrorIncludes500StatusWithoutEnvelopeMessage() {
        let provider = OpenAITextTransformProvider(apiKey: "test-key")
        let data = Data("Internal Server Error".utf8)

        let error = provider.makeHTTPError(statusCode: 500, data: data)

        XCTAssertEqual(error.localizedDescription, "OpenAI request failed with HTTP 500")
    }

    func testEmptyResponseLocalizedDescriptionIsUseful() {
        let error = OpenAITextTransformError.emptyResponse

        XCTAssertEqual(error.localizedDescription, "OpenAI returned an empty text response.")
    }
}
