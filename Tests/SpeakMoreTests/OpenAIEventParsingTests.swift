import AVFoundation
import XCTest
@testable import SpeakMore

final class OpenAIEventParsingTests: XCTestCase {
    func testParsesTranscriptDeltaEvent() throws {
        let json = """
        {"type":"conversation.item.input_audio_transcription.delta","delta":"hello"}
        """.data(using: .utf8)!

        let delta = try OpenAIRealtimeTranscriptionProvider.parseDeltaEvent(json)

        XCTAssertEqual(delta, TranscriptDelta(text: "hello", isFinal: false))
    }

    func testParsesCompletedTranscriptEvent() throws {
        let json = """
        {"type":"conversation.item.input_audio_transcription.completed","transcript":"hello world"}
        """.data(using: .utf8)!

        let delta = try OpenAIRealtimeTranscriptionProvider.parseDeltaEvent(json)

        XCTAssertEqual(delta, TranscriptDelta(text: "hello world", isFinal: true))
    }

    @MainActor
    func testSessionUpdateConfiguresRealtimeWhisperPCM24k() throws {
        let provider = OpenAIRealtimeTranscriptionProvider(apiKey: "test-key")

        let data = try provider.makeSessionUpdateEventData()
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let session = try XCTUnwrap(object["session"] as? [String: Any])
        let audio = try XCTUnwrap(session["audio"] as? [String: Any])
        let input = try XCTUnwrap(audio["input"] as? [String: Any])
        let format = try XCTUnwrap(input["format"] as? [String: Any])
        let transcription = try XCTUnwrap(input["transcription"] as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "session.update")
        XCTAssertEqual(session["type"] as? String, "transcription")
        XCTAssertEqual(format["type"] as? String, "audio/pcm")
        XCTAssertEqual(format["rate"] as? Int, 24_000)
        XCTAssertEqual(transcription["model"] as? String, "gpt-realtime-whisper")
        XCTAssertEqual(transcription["language"] as? String, "zh")
        XCTAssertEqual(transcription["delay"] as? String, "low")
    }

    @MainActor
    func testAppendEventContainsBase64Audio() throws {
        let provider = OpenAIRealtimeTranscriptionProvider(apiKey: "test-key")

        let data = try provider.makeAppendEventData(audioData: Data([0x01, 0x02, 0xff]))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "input_audio_buffer.append")
        XCTAssertEqual(object["audio"] as? String, "AQL/")
    }

    @MainActor
    func testCommitEventContainsCommitType() throws {
        let provider = OpenAIRealtimeTranscriptionProvider(apiKey: "test-key")

        let data = try provider.makeCommitEventData()
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "input_audio_buffer.commit")
    }

    @MainActor
    func testStartUsesAuthorizationHeaderWithoutBetaHeader() async throws {
        let client = RecordingWebSocketClient()
        let factory = RecordingWebSocketFactory(client: client)
        let provider = OpenAIRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: factory,
            audioCaptureEngine: NoOpAudioCaptureEngine()
        )

        let stream = provider.startTranscription()
        _ = stream.makeAsyncIterator()
        await waitForSentMessageCount(1, client: client)

        XCTAssertEqual(factory.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        XCTAssertNil(factory.lastRequest?.value(forHTTPHeaderField: "OpenAI-Beta"))

        provider.abort()
    }

    @MainActor
    func testSessionUpdateIsSentAsTextWebSocketFrame() async throws {
        let client = RecordingWebSocketClient()
        let provider = OpenAIRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: RecordingWebSocketFactory(client: client),
            audioCaptureEngine: NoOpAudioCaptureEngine()
        )

        let stream = provider.startTranscription()
        _ = stream.makeAsyncIterator()
        await waitForSentMessageCount(1, client: client)

        guard case let .text(text) = client.sentMessages[0] else {
            return XCTFail("Expected session update to be sent as a text WebSocket frame.")
        }
        let data = try XCTUnwrap(text.data(using: .utf8))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["type"] as? String, "session.update")

        provider.abort()
    }

    @MainActor
    func testStopSendsCommitWithoutCancelingSocket() async throws {
        let client = RecordingWebSocketClient()
        let provider = OpenAIRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: RecordingWebSocketFactory(client: client),
            audioCaptureEngine: NoOpAudioCaptureEngine(),
            commitTimeoutNanoseconds: 60_000_000_000
        )

        let stream = provider.startTranscription()
        _ = stream.makeAsyncIterator()
        await waitForSentMessageCount(1, client: client)

        provider.stop()
        await waitForSentMessageCount(2, client: client)

        let lastObject = try XCTUnwrap(JSONSerialization.jsonObject(with: client.sentMessages[1].data) as? [String: Any])
        XCTAssertEqual(lastObject["type"] as? String, "input_audio_buffer.commit")
        XCTAssertEqual(client.cancelCallCount, 0)

        provider.abort()
    }

    @MainActor
    func testStopClosesSocketAfterCompletedTranscriptArrives() async throws {
        let client = RecordingWebSocketClient()
        let provider = OpenAIRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: RecordingWebSocketFactory(client: client),
            audioCaptureEngine: NoOpAudioCaptureEngine(),
            commitTimeoutNanoseconds: 60_000_000_000
        )

        let stream = provider.startTranscription()
        _ = stream.makeAsyncIterator()
        await waitForSentMessageCount(1, client: client)

        provider.stop()
        await waitForSentMessageCount(2, client: client)
        XCTAssertEqual(client.cancelCallCount, 0)

        client.enqueueReceivedMessage(Data("""
        {"type":"conversation.item.input_audio_transcription.completed","transcript":"done"}
        """.utf8))
        await waitForCancelCallCount(1, client: client)

        XCTAssertEqual(client.cancelCallCount, 1)
    }

    @MainActor
    func testStopWhileSessionUpdateIsSuspendedStopsEarlyAudioAndStillCommits() async throws {
        let client = RecordingWebSocketClient(suspendFirstSend: true)
        let audioCapture = NoOpAudioCaptureEngine()
        let provider = OpenAIRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: RecordingWebSocketFactory(client: client),
            audioCaptureEngine: audioCapture,
            commitTimeoutNanoseconds: 60_000_000_000
        )

        let stream = provider.startTranscription()
        _ = stream.makeAsyncIterator()
        await waitForSendAttemptCount(1, client: client)
        await waitForAudioStartCount(1, audioCapture: audioCapture)

        provider.stop()
        await waitForSendAttemptCount(2, client: client)
        XCTAssertEqual(audioCapture.startCallCount, 1)
        XCTAssertEqual(audioCapture.stopCallCount, 1)

        client.resumeSuspendedSend()
        await waitForSentMessageCount(2, client: client)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(audioCapture.startCallCount, 1)

        let sentTypes = try client.sentMessages.map { message in
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: message.data) as? [String: Any])
            return object["type"] as? String
        }
        XCTAssertTrue(sentTypes.contains("input_audio_buffer.commit"))

        provider.abort()
    }

    @MainActor
    func testAudioCapturedDuringConnectionIsSentAfterSessionUpdate() async throws {
        let client = RecordingWebSocketClient(suspendFirstSend: true)
        let audioCapture = NoOpAudioCaptureEngine()
        let provider = OpenAIRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: RecordingWebSocketFactory(client: client),
            audioCaptureEngine: audioCapture
        )

        let stream = provider.startTranscription()
        _ = stream.makeAsyncIterator()
        await waitForSendAttemptCount(1, client: client)
        await waitForAudioStartCount(1, audioCapture: audioCapture)

        try audioCapture.emit(buffer: makeSilentPCMBuffer(sampleRate: 24_000))
        XCTAssertEqual(client.sentMessages.count, 0)

        client.resumeSuspendedSend()
        await waitForSentMessageCount(2, client: client)

        let firstObject = try XCTUnwrap(JSONSerialization.jsonObject(with: client.sentMessages[0].data) as? [String: Any])
        let secondObject = try XCTUnwrap(JSONSerialization.jsonObject(with: client.sentMessages[1].data) as? [String: Any])
        XCTAssertEqual(firstObject["type"] as? String, "session.update")
        XCTAssertEqual(secondObject["type"] as? String, "input_audio_buffer.append")

        provider.abort()
    }

    @MainActor
    func testStopBeforeStartIsCleanNoOp() {
        let client = RecordingWebSocketClient()
        let provider = OpenAIRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: RecordingWebSocketFactory(client: client),
            audioCaptureEngine: NoOpAudioCaptureEngine()
        )

        provider.stop()

        XCTAssertEqual(client.sentMessages.count, 0)
        XCTAssertEqual(client.cancelCallCount, 0)
    }

    func testPCM16ConversionClampsAndUsesLittleEndian() {
        let samples: [Float] = [-2.0, -1.0, 0.0, 0.5, 2.0]

        let data = OpenAIRealtimeTranscriptionProvider.makePCM16Data(fromMonoFloatSamples: samples)

        XCTAssertEqual(Array(data), [
            0x00, 0x80,
            0x00, 0x80,
            0x00, 0x00,
            0xff, 0x3f,
            0xff, 0x7f
        ])
    }

    @MainActor
    private func waitForSentMessageCount(
        _ expectedCount: Int,
        client: RecordingWebSocketClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where client.sentMessages.count < expectedCount {
            await Task.yield()
        }

        XCTAssertGreaterThanOrEqual(client.sentMessages.count, expectedCount, file: file, line: line)
    }

    @MainActor
    private func waitForSendAttemptCount(
        _ expectedCount: Int,
        client: RecordingWebSocketClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where client.sendAttemptCount < expectedCount {
            await Task.yield()
        }

        XCTAssertGreaterThanOrEqual(client.sendAttemptCount, expectedCount, file: file, line: line)
    }

    @MainActor
    private func waitForCancelCallCount(
        _ expectedCount: Int,
        client: RecordingWebSocketClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where client.cancelCallCount < expectedCount {
            await Task.yield()
        }

        XCTAssertGreaterThanOrEqual(client.cancelCallCount, expectedCount, file: file, line: line)
    }

    @MainActor
    private func waitForAudioStartCount(
        _ expectedCount: Int,
        audioCapture: NoOpAudioCaptureEngine,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where audioCapture.startCallCount < expectedCount {
            await Task.yield()
        }

        XCTAssertGreaterThanOrEqual(audioCapture.startCallCount, expectedCount, file: file, line: line)
    }
}

private final class RecordingWebSocketFactory: OpenAIRealtimeWebSocketFactory {
    private let client: RecordingWebSocketClient
    private(set) var lastRequest: URLRequest?

    init(client: RecordingWebSocketClient) {
        self.client = client
    }

    func makeClient(request: URLRequest) -> OpenAIRealtimeWebSocketClient {
        lastRequest = request
        return client
    }
}

private final class RecordingWebSocketClient: OpenAIRealtimeWebSocketClient {
    private(set) var resumeCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var sendAttemptCount = 0
    private(set) var sentMessages: [OpenAIRealtimeWebSocketMessage] = []
    private var receivedMessages: [Data] = []
    private let suspendFirstSend: Bool
    private var suspendedSendContinuation: CheckedContinuation<Void, Never>?

    init(suspendFirstSend: Bool = false) {
        self.suspendFirstSend = suspendFirstSend
    }

    func resume() {
        resumeCallCount += 1
    }

    func send(_ message: OpenAIRealtimeWebSocketMessage) async throws {
        sendAttemptCount += 1
        if suspendFirstSend && sendAttemptCount == 1 {
            await withCheckedContinuation { continuation in
                suspendedSendContinuation = continuation
            }
        }
        sentMessages.append(message)
    }

    func receive() async throws -> Data {
        for _ in 0..<100 {
            if !receivedMessages.isEmpty {
                return receivedMessages.removeFirst()
            }

            try await Task.sleep(nanoseconds: 1_000_000)
        }

        throw CancellationError()
    }

    func cancel() {
        cancelCallCount += 1
    }

    func enqueueReceivedMessage(_ data: Data) {
        receivedMessages.append(data)
    }

    func resumeSuspendedSend() {
        suspendedSendContinuation?.resume()
        suspendedSendContinuation = nil
    }
}

private final class NoOpAudioCaptureEngine: AudioCapturing {
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private var onBuffer: ((AVAudioPCMBuffer) -> Void)?

    func start(onBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws {
        startCallCount += 1
        self.onBuffer = onBuffer
    }

    func stop() {
        stopCallCount += 1
    }

    func emit(buffer: AVAudioPCMBuffer) {
        onBuffer?(buffer)
    }
}

private func makeSilentPCMBuffer(sampleRate: Double) throws -> AVAudioPCMBuffer {
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!
    let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8))
    buffer.frameLength = 8
    return buffer
}
