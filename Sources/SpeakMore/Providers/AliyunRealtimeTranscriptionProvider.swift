@preconcurrency import AVFoundation
import Foundation

@MainActor
final class AliyunRealtimeTranscriptionProvider {
    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let webSocketFactory: OpenAIRealtimeWebSocketFactory
    private let audioCaptureEngine: AudioCapturing
    private let commitTimeoutNanoseconds: UInt64
    private var webSocketClient: OpenAIRealtimeWebSocketClient?
    private var receiveTask: Task<Void, Never>?
    private var commitTimeoutTask: Task<Void, Never>?
    private var continuation: AsyncThrowingStream<TranscriptDelta, Error>.Continuation?
    private var lifecycleState: LifecycleState = .finished
    private var isAudioCaptureRunning = false
    private var pendingAudioData: [Data] = []
    private let maxPendingAudioChunkCount = 120

    init(
        apiKey: String,
        model: String = "qwen3-asr-flash-realtime",
        endpoint: URL = URL(string: "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime")!,
        session: URLSession = .shared,
        audioCaptureEngine: AudioCapturing = AudioCaptureEngine(),
        commitTimeoutNanoseconds: UInt64 = 10_000_000_000
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = Self.endpointWithModel(endpoint: endpoint, model: model)
        self.webSocketFactory = URLSessionAliyunRealtimeWebSocketFactory(session: session)
        self.audioCaptureEngine = audioCaptureEngine
        self.commitTimeoutNanoseconds = commitTimeoutNanoseconds
    }

    init(
        apiKey: String,
        model: String = "qwen3-asr-flash-realtime",
        endpoint: URL = URL(string: "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime")!,
        webSocketFactory: OpenAIRealtimeWebSocketFactory,
        audioCaptureEngine: AudioCapturing,
        commitTimeoutNanoseconds: UInt64 = 10_000_000_000
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = Self.endpointWithModel(endpoint: endpoint, model: model)
        self.webSocketFactory = webSocketFactory
        self.audioCaptureEngine = audioCaptureEngine
        self.commitTimeoutNanoseconds = commitTimeoutNanoseconds
    }

    func makeSessionUpdateEventData() throws -> Data {
        let payload: [String: Any] = [
            "event_id": Self.eventID(),
            "type": "session.update",
            "session": [
                "modalities": ["text"],
                "input_audio_format": "pcm",
                "sample_rate": 16_000,
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.2,
                    "silence_duration_ms": 600
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    func makeAppendEventData(audioData: Data) throws -> Data {
        let payload: [String: Any] = [
            "event_id": Self.eventID(),
            "type": "input_audio_buffer.append",
            "audio": audioData.base64EncodedString()
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    func makeFinishEventData() throws -> Data {
        let payload: [String: Any] = [
            "event_id": Self.eventID(),
            "type": "session.finish"
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    nonisolated static func parseDeltaEvent(_ data: Data) throws -> TranscriptDelta {
        let event = try JSONDecoder().decode(AliyunRealtimeServerEvent.self, from: data)
        switch event.type {
        case "conversation.item.input_audio_transcription.text":
            return TranscriptDelta(text: (event.text ?? "") + (event.stash ?? ""), isFinal: false, replacesPrevious: true)
        case "conversation.item.input_audio_transcription.completed":
            guard let transcript = event.transcript else { throw AliyunRealtimeTranscriptionError.missingTranscriptText }
            return TranscriptDelta(text: transcript, isFinal: true, replacesPrevious: true)
        case "conversation.item.input_audio_transcription.failed":
            throw AliyunRealtimeTranscriptionError.serverError(event.error?.message ?? "Aliyun realtime transcription failed.")
        case "error":
            throw AliyunRealtimeTranscriptionError.serverError(event.error?.message ?? "Aliyun realtime transcription failed.")
        case "session.finished":
            return TranscriptDelta(text: "", isFinal: true)
        default:
            throw AliyunRealtimeTranscriptionError.unsupportedEvent(event.type)
        }
    }

    nonisolated static func makePCM16Data(fromMonoFloatSamples samples: [Float]) -> Data {
        OpenAIRealtimeTranscriptionProvider.makePCM16Data(fromMonoFloatSamples: samples)
    }

    nonisolated static func makePCM16AudioData(from buffer: AVAudioPCMBuffer) throws -> Data {
        let targetSampleRate = 16_000.0
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )!

        let monoBuffer: AVAudioPCMBuffer
        if buffer.format.commonFormat == .pcmFormatFloat32,
           buffer.format.sampleRate == targetSampleRate,
           buffer.format.channelCount == 1 {
            monoBuffer = buffer
        } else {
            guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
                throw AliyunRealtimeTranscriptionError.audioConversionFailed("Unable to create audio converter.")
            }

            let ratio = targetSampleRate / buffer.format.sampleRate
            let frameCapacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else {
                throw AliyunRealtimeTranscriptionError.audioConversionFailed("Unable to allocate converted audio buffer.")
            }

            let inputProvider = AliyunConverterInputProvider(buffer: buffer)
            var conversionError: NSError?
            let status = converter.convert(to: converted, error: &conversionError) { _, outStatus in
                guard let inputBuffer = inputProvider.takeBuffer() else {
                    outStatus.pointee = .endOfStream
                    return nil
                }

                outStatus.pointee = .haveData
                return inputBuffer
            }

            guard status != .error else {
                let reason = conversionError?.localizedDescription ?? "Audio converter returned an error."
                throw AliyunRealtimeTranscriptionError.audioConversionFailed(reason)
            }
            monoBuffer = converted
        }

        guard let channel = monoBuffer.floatChannelData?[0] else {
            throw AliyunRealtimeTranscriptionError.audioConversionFailed("Converted audio was not Float32 PCM.")
        }

        let sampleCount = Int(monoBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channel, count: sampleCount))
        return makePCM16Data(fromMonoFloatSamples: samples)
    }

    nonisolated private static func parseRecognizedDeltaEvent(_ data: Data) throws -> TranscriptDelta? {
        do {
            let delta = try parseDeltaEvent(data)
            if delta.text.isEmpty && delta.isFinal {
                return nil
            }
            return delta
        } catch AliyunRealtimeTranscriptionError.unsupportedEvent {
            return nil
        }
    }

    private func connectAndStartAudio() async throws {
        guard lifecycleState == .connecting else { return }

        try startAudioCapture()

        var request = URLRequest(url: endpoint)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        let client = webSocketFactory.makeClient(request: request)
        webSocketClient = client
        client.resume()

        receiveTask = Task { [weak self] in
            await self?.receiveMessages()
        }

        try await sendSessionUpdate()
        guard lifecycleState == .connecting else { return }

        lifecycleState = .listening
        await flushPendingAudioData()
    }

    private func startAudioCapture() throws {
        try audioCaptureEngine.start { [weak self] buffer in
            do {
                let audioData = try Self.makePCM16AudioData(from: buffer)
                Task { @MainActor [weak self] in
                    await self?.sendAudioData(audioData)
                }
            } catch {
                Task { @MainActor [weak self] in
                    self?.finish(throwing: error)
                }
            }
        }
        isAudioCaptureRunning = true
    }

    private func stopAudioCapture() {
        guard isAudioCaptureRunning else { return }
        audioCaptureEngine.stop()
        isAudioCaptureRunning = false
    }

    private func receiveMessages() async {
        guard let webSocketClient else { return }

        while !Task.isCancelled {
            do {
                let data = try await webSocketClient.receive()

                if let delta = try Self.parseRecognizedDeltaEvent(data) {
                    continuation?.yield(delta)
                } else if Self.isSessionFinishedEvent(data) {
                    complete()
                }
            } catch is CancellationError {
                return
            } catch {
                finish(throwing: error)
                return
            }
        }
    }

    private func sendSessionUpdate() async throws {
        let data = try makeSessionUpdateEventData()
        try await sendWebSocketEvent(data)
    }

    private func sendAudioData(_ audioData: Data) async {
        guard !audioData.isEmpty else { return }

        if lifecycleState == .connecting {
            pendingAudioData.append(audioData)
            if pendingAudioData.count > maxPendingAudioChunkCount {
                pendingAudioData.removeFirst(pendingAudioData.count - maxPendingAudioChunkCount)
            }
            return
        }

        guard lifecycleState == .listening else { return }

        do {
            let data = try makeAppendEventData(audioData: audioData)
            try await sendWebSocketEvent(data)
        } catch {
            finish(throwing: error)
        }
    }

    private func flushPendingAudioData() async {
        let queuedAudio = pendingAudioData
        pendingAudioData.removeAll()

        for audioData in queuedAudio {
            await sendAudioData(audioData)
        }
    }

    private func sendFinishAndWaitForCompletion() {
        stopAudioCapture()
        switch lifecycleState {
        case .finished, .stopping:
            return
        case .connecting, .listening:
            break
        }

        guard let webSocketClient else {
            finish(throwing: AliyunRealtimeTranscriptionError.noActiveWebSocket)
            return
        }

        lifecycleState = .stopping

        Task { [weak self] in
            do {
                guard let self else { return }
                guard self.lifecycleState == .stopping else { return }
                let data = try self.makeFinishEventData()
                try await self.sendWebSocketEvent(data, using: webSocketClient)
                guard self.lifecycleState == .stopping else { return }
                self.startCommitTimeout()
            } catch {
                self?.finish(throwing: error)
            }
        }
    }

    private func sendWebSocketEvent(
        _ data: Data,
        using client: OpenAIRealtimeWebSocketClient? = nil
    ) async throws {
        guard let text = String(data: data, encoding: .utf8) else {
            throw AliyunRealtimeTranscriptionError.invalidOutboundMessage
        }

        try await (client ?? webSocketClient)?.send(.text(text))
    }

    private func startCommitTimeout() {
        commitTimeoutTask?.cancel()
        commitTimeoutTask = Task { [weak self] in
            do {
                guard let self else { return }
                try await Task.sleep(nanoseconds: self.commitTimeoutNanoseconds)
                self.finish(throwing: AliyunRealtimeTranscriptionError.commitTimedOut)
            } catch is CancellationError {
                return
            } catch {
                self?.finish(throwing: error)
            }
        }
    }

    private func complete() {
        finish()
    }

    private func finish(throwing error: Error? = nil, shouldCancelSocket: Bool = true) {
        stopAudioCapture()
        pendingAudioData.removeAll()
        lifecycleState = .finished
        commitTimeoutTask?.cancel()
        commitTimeoutTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        if shouldCancelSocket {
            webSocketClient?.cancel()
        }
        webSocketClient = nil

        if let error {
            continuation?.finish(throwing: error)
        } else {
            continuation?.finish()
        }
        continuation = nil
    }

    private static func endpointWithModel(endpoint: URL, model: String) -> URL {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return endpoint
        }

        var queryItems = components.queryItems ?? []
        if !queryItems.contains(where: { $0.name == "model" }) {
            queryItems.append(URLQueryItem(name: "model", value: model))
            components.queryItems = queryItems
        }
        return components.url ?? endpoint
    }

    private static func eventID() -> String {
        "event_\(UUID().uuidString)"
    }

    private static func isSessionFinishedEvent(_ data: Data) -> Bool {
        guard let event = try? JSONDecoder().decode(AliyunRealtimeServerEvent.self, from: data) else {
            return false
        }
        return event.type == "session.finished"
    }
}

extension AliyunRealtimeTranscriptionProvider: RealtimeTranscriptionProvider {
    func startTranscription() -> AsyncThrowingStream<TranscriptDelta, Error> {
        AsyncThrowingStream { continuation in
            self.abort()
            self.continuation = continuation
            self.lifecycleState = .connecting
            self.pendingAudioData.removeAll()

            Task { @MainActor in
                do {
                    try await self.connectAndStartAudio()
                } catch {
                    self.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.abort()
                }
            }
        }
    }

    func stop() {
        sendFinishAndWaitForCompletion()
    }

    func abort() {
        finish()
    }
}

enum AliyunRealtimeTranscriptionError: LocalizedError, Equatable {
    case unsupportedEvent(String)
    case missingTranscriptText
    case serverError(String)
    case audioConversionFailed(String)
    case commitTimedOut
    case noActiveWebSocket
    case invalidOutboundMessage

    var errorDescription: String? {
        switch self {
        case let .unsupportedEvent(type):
            return "Aliyun realtime returned unsupported event: \(type)"
        case .missingTranscriptText:
            return "Aliyun realtime transcription event did not include transcript text."
        case let .serverError(message):
            return "Aliyun realtime transcription failed: \(message)"
        case let .audioConversionFailed(message):
            return "Could not prepare microphone audio for Aliyun realtime transcription: \(message)"
        case .commitTimedOut:
            return "Timed out waiting for Aliyun realtime transcription to finish."
        case .noActiveWebSocket:
            return "Cannot finish Aliyun realtime transcription because no websocket is active."
        case .invalidOutboundMessage:
            return "Could not prepare the Aliyun realtime websocket message."
        }
    }
}

private struct AliyunRealtimeServerEvent: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let type: String
    let text: String?
    let stash: String?
    let transcript: String?
    let error: APIError?
}

private enum LifecycleState {
    case connecting
    case listening
    case stopping
    case finished
}

private final class AliyunConverterInputProvider: @unchecked Sendable {
    private var buffer: AVAudioPCMBuffer?

    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }

    func takeBuffer() -> AVAudioPCMBuffer? {
        defer { buffer = nil }
        return buffer
    }
}

private struct URLSessionAliyunRealtimeWebSocketFactory: OpenAIRealtimeWebSocketFactory {
    let session: URLSession

    func makeClient(request: URLRequest) -> OpenAIRealtimeWebSocketClient {
        URLSessionAliyunRealtimeWebSocketClient(task: session.webSocketTask(with: request))
    }
}

private final class URLSessionAliyunRealtimeWebSocketClient: OpenAIRealtimeWebSocketClient {
    private let task: URLSessionWebSocketTask

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    func resume() {
        task.resume()
    }

    func send(_ message: OpenAIRealtimeWebSocketMessage) async throws {
        switch message {
        case let .text(text):
            try await task.send(.string(text))
        }
    }

    func receive() async throws -> Data {
        let message = try await task.receive()
        switch message {
        case let .data(data):
            return data
        case let .string(string):
            return Data(string.utf8)
        @unknown default:
            return Data()
        }
    }

    func cancel() {
        task.cancel(with: .goingAway, reason: nil)
    }
}
