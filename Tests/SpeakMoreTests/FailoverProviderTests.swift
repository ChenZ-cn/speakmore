import XCTest
@testable import SpeakMore

@MainActor
final class FailoverProviderTests: XCTestCase {
    func testTextProviderUsesBackupAfterRetriableHTTPError() async throws {
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "hello",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )
        let expected = VoiceSessionResult(rawTranscript: "hello", finalText: "backup", shouldReplaceSelection: false)
        let primary = StubTextTransformProvider(result: .failure(OpenAITextTransformError.httpStatus(429, message: "quota")))
        let backup = StubTextTransformProvider(result: .success(expected))
        let provider = FailoverTextTransformProvider(providers: [primary, backup])

        let result = try await provider.transform(input: input)

        XCTAssertEqual(result, expected)
        XCTAssertEqual(primary.callCount, 1)
        XCTAssertEqual(backup.callCount, 1)
    }

    func testTextProviderDoesNotUseBackupForNonRetriableError() async {
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "hello",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )
        let primary = StubTextTransformProvider(result: .failure(OpenAITextTransformError.emptyResponse))
        let backup = StubTextTransformProvider(
            result: .success(VoiceSessionResult(rawTranscript: "hello", finalText: "backup", shouldReplaceSelection: false))
        )
        let provider = FailoverTextTransformProvider(providers: [primary, backup])

        await XCTAssertThrowsErrorAsync(try await provider.transform(input: input))

        XCTAssertEqual(primary.callCount, 1)
        XCTAssertEqual(backup.callCount, 0)
    }

    func testRealtimeProviderUsesBackupWhenPrimaryFailsBeforeTranscript() async throws {
        let primary = StubRealtimeTranscriptionProvider(events: [
            .failure(OpenAIRealtimeTranscriptionError.serverError("quota"))
        ])
        let backup = StubRealtimeTranscriptionProvider(events: [
            .delta(TranscriptDelta(text: "backup transcript", isFinal: true))
        ])
        let provider = FailoverRealtimeTranscriptionProvider(providers: [primary, backup])

        let deltas = try await collect(provider.startTranscription())

        XCTAssertEqual(deltas, [TranscriptDelta(text: "backup transcript", isFinal: true)])
        XCTAssertEqual(primary.startCallCount, 1)
        XCTAssertEqual(primary.abortCallCount, 1)
        XCTAssertEqual(backup.startCallCount, 1)
    }

    func testRealtimeProviderDoesNotSwitchAfterTranscriptHasStarted() async throws {
        let primary = StubRealtimeTranscriptionProvider(events: [
            .delta(TranscriptDelta(text: "partial", isFinal: false)),
            .failure(OpenAIRealtimeTranscriptionError.serverError("quota"))
        ])
        let backup = StubRealtimeTranscriptionProvider(events: [
            .delta(TranscriptDelta(text: "backup transcript", isFinal: true))
        ])
        let provider = FailoverRealtimeTranscriptionProvider(providers: [primary, backup])

        do {
            _ = try await collect(provider.startTranscription())
            XCTFail("Expected realtime stream to throw.")
        } catch OpenAIRealtimeTranscriptionError.serverError {
            XCTAssertEqual(primary.startCallCount, 1)
            XCTAssertEqual(backup.startCallCount, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func collect(
        _ stream: AsyncThrowingStream<TranscriptDelta, Error>
    ) async throws -> [TranscriptDelta] {
        var deltas: [TranscriptDelta] = []
        for try await delta in stream {
            deltas.append(delta)
        }
        return deltas
    }

    private func XCTAssertThrowsErrorAsync(
        _ expression: @autoclosure () async throws -> Any,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown.", file: file, line: line)
        } catch {
            return
        }
    }
}

@MainActor
private final class StubTextTransformProvider: TextTransformProvider {
    private let result: Result<VoiceSessionResult, Error>
    private(set) var callCount = 0

    init(result: Result<VoiceSessionResult, Error>) {
        self.result = result
    }

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        callCount += 1
        return try result.get()
    }
}

@MainActor
private final class StubRealtimeTranscriptionProvider: RealtimeTranscriptionProvider {
    enum Event {
        case delta(TranscriptDelta)
        case failure(Error)
    }

    private let events: [Event]
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var abortCallCount = 0

    init(events: [Event]) {
        self.events = events
    }

    func startTranscription() -> AsyncThrowingStream<TranscriptDelta, Error> {
        startCallCount += 1
        let events = events

        return AsyncThrowingStream { continuation in
            for event in events {
                switch event {
                case let .delta(delta):
                    continuation.yield(delta)
                case let .failure(error):
                    continuation.finish(throwing: error)
                    return
                }
            }

            continuation.finish()
        }
    }

    func stop() {
        stopCallCount += 1
    }

    func abort() {
        abortCallCount += 1
    }
}
