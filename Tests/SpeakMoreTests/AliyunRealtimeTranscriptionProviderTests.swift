import AVFoundation
import XCTest
@testable import SpeakMore

final class AliyunRealtimeTranscriptionProviderTests: XCTestCase {
    @MainActor
    func testSessionUpdateConfiguresQwenASRRealtimePCM16kWithVAD() throws {
        let provider = AliyunRealtimeTranscriptionProvider(apiKey: "test-key")

        let data = try provider.makeSessionUpdateEventData()
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let session = try XCTUnwrap(object["session"] as? [String: Any])
        let turnDetection = try XCTUnwrap(session["turn_detection"] as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "session.update")
        XCTAssertNotNil(object["event_id"] as? String)
        XCTAssertEqual(session["input_audio_format"] as? String, "pcm")
        XCTAssertEqual(session["sample_rate"] as? Int, 16_000)
        XCTAssertNil(session["input_audio_transcription"])
        XCTAssertEqual(turnDetection["type"] as? String, "server_vad")
        XCTAssertEqual(turnDetection["threshold"] as? Double, 0.2)
        XCTAssertEqual(turnDetection["silence_duration_ms"] as? Int, 600)
    }

    @MainActor
    func testFinishEventContainsSessionFinishType() throws {
        let provider = AliyunRealtimeTranscriptionProvider(apiKey: "test-key")

        let data = try provider.makeFinishEventData()
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "session.finish")
        XCTAssertNotNil(object["event_id"] as? String)
    }

    func testParsesRealtimeTextEventFromTextAndStash() throws {
        let json = Data("""
        {
            "type":"conversation.item.input_audio_transcription.text",
            "text":"今天天气",
            "stash":"不错"
        }
        """.utf8)

        let delta = try AliyunRealtimeTranscriptionProvider.parseDeltaEvent(json)

        XCTAssertEqual(delta, TranscriptDelta(text: "今天天气不错", isFinal: false, replacesPrevious: true))
    }

    func testParsesCompletedTranscriptEvent() throws {
        let json = Data("""
        {
            "type":"conversation.item.input_audio_transcription.completed",
            "transcript":"今天天气不错"
        }
        """.utf8)

        let delta = try AliyunRealtimeTranscriptionProvider.parseDeltaEvent(json)

        XCTAssertEqual(delta, TranscriptDelta(text: "今天天气不错", isFinal: true, replacesPrevious: true))
    }

    @MainActor
    func testCompletedUtteranceDoesNotCloseSocketBeforeSessionFinished() async throws {
        let client = AliyunRecordingWebSocketClient()
        let provider = AliyunRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: AliyunRecordingWebSocketFactory(client: client),
            audioCaptureEngine: AliyunNoOpAudioCaptureEngine(),
            commitTimeoutNanoseconds: 60_000_000_000
        )

        let stream = provider.startTranscription()
        let nextDelta = Task { () throws -> TranscriptDelta? in
            var iterator = stream.makeAsyncIterator()
            return try await iterator.next()
        }
        await waitForSentMessageCount(1, client: client)

        client.enqueueReceivedMessage(Data("""
        {"type":"conversation.item.input_audio_transcription.completed","transcript":"第一句。"}
        """.utf8))

        let delta = try await nextDelta.value
        XCTAssertEqual(delta, TranscriptDelta(text: "第一句。", isFinal: true, replacesPrevious: true))
        XCTAssertEqual(client.cancelCallCount, 0)

        client.enqueueReceivedMessage(Data("""
        {"type":"session.finished"}
        """.utf8))
        await waitForCancelCallCount(1, client: client)

        XCTAssertEqual(client.cancelCallCount, 1)
    }

    @MainActor
    func testAudioCapturedDuringConnectionIsSentAfterSessionUpdate() async throws {
        let client = AliyunRecordingWebSocketClient(suspendFirstSend: true)
        let audioCapture = AliyunNoOpAudioCaptureEngine()
        let provider = AliyunRealtimeTranscriptionProvider(
            apiKey: "test-key",
            webSocketFactory: AliyunRecordingWebSocketFactory(client: client),
            audioCaptureEngine: audioCapture,
            commitTimeoutNanoseconds: 60_000_000_000
        )

        let stream = provider.startTranscription()
        _ = stream.makeAsyncIterator()
        await waitForSendAttemptCount(1, client: client)
        await waitForAudioStartCount(1, audioCapture: audioCapture)

        try audioCapture.emit(buffer: makeAliyunSilentPCMBuffer(sampleRate: 16_000))
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
    private func waitForSentMessageCount(
        _ expectedCount: Int,
        client: AliyunRecordingWebSocketClient,
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
        client: AliyunRecordingWebSocketClient,
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
        client: AliyunRecordingWebSocketClient,
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
        audioCapture: AliyunNoOpAudioCaptureEngine,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where audioCapture.startCallCount < expectedCount {
            await Task.yield()
        }

        XCTAssertGreaterThanOrEqual(audioCapture.startCallCount, expectedCount, file: file, line: line)
    }
}

private final class AliyunRecordingWebSocketFactory: OpenAIRealtimeWebSocketFactory {
    private let client: AliyunRecordingWebSocketClient

    init(client: AliyunRecordingWebSocketClient) {
        self.client = client
    }

    func makeClient(request: URLRequest) -> OpenAIRealtimeWebSocketClient {
        client
    }
}

private final class AliyunRecordingWebSocketClient: OpenAIRealtimeWebSocketClient {
    private(set) var cancelCallCount = 0
    private(set) var sendAttemptCount = 0
    private(set) var sentMessages: [OpenAIRealtimeWebSocketMessage] = []
    private var receivedMessages: [Data] = []
    private let suspendFirstSend: Bool
    private var suspendedSendContinuation: CheckedContinuation<Void, Never>?

    init(suspendFirstSend: Bool = false) {
        self.suspendFirstSend = suspendFirstSend
    }

    func resume() {}

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

private final class AliyunNoOpAudioCaptureEngine: AudioCapturing {
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

private func makeAliyunSilentPCMBuffer(sampleRate: Double) throws -> AVAudioPCMBuffer {
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!
    let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8))
    buffer.frameLength = 8
    return buffer
}
