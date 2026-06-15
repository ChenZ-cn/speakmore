@preconcurrency import AVFoundation
import Foundation

@MainActor
final class OpenAIRealtimeTranscriptionProvider {
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
        model: String = "gpt-realtime-whisper",
        endpoint: URL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!,
        session: URLSession = .shared,
        audioCaptureEngine: AudioCapturing = AudioCaptureEngine(),
        commitTimeoutNanoseconds: UInt64 = 10_000_000_000
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.webSocketFactory = URLSessionOpenAIRealtimeWebSocketFactory(session: session)
        self.audioCaptureEngine = audioCaptureEngine
        self.commitTimeoutNanoseconds = commitTimeoutNanoseconds
    }

    init(
        apiKey: String,
        model: String = "gpt-realtime-whisper",
        endpoint: URL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!,
        webSocketFactory: OpenAIRealtimeWebSocketFactory,
        audioCaptureEngine: AudioCapturing,
        commitTimeoutNanoseconds: UInt64 = 10_000_000_000
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.webSocketFactory = webSocketFactory
        self.audioCaptureEngine = audioCaptureEngine
        self.commitTimeoutNanoseconds = commitTimeoutNanoseconds
    }

    func makeSessionUpdateEventData() throws -> Data {
        let payload: [String: Any] = [
            "type": "session.update",
            "session": [
                "type": "transcription",
                "audio": [
                    "input": [
                        "format": [
                            "type": "audio/pcm",
                            "rate": 24_000
                        ],
                        "transcription": [
                            "model": model,
                            "language": "zh",
                            "delay": "low"
                        ]
                    ]
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    func makeAppendEventData(audioData: Data) throws -> Data {
        let payload: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": audioData.base64EncodedString()
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    func makeCommitEventData() throws -> Data {
        let payload: [String: Any] = [
            "type": "input_audio_buffer.commit"
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    nonisolated static func parseDeltaEvent(_ data: Data) throws -> TranscriptDelta {
        let event = try JSONDecoder().decode(RealtimeServerEvent.self, from: data)
        switch event.type {
        case "conversation.item.input_audio_transcription.delta":
            guard let delta = event.delta else { throw OpenAIRealtimeTranscriptionError.missingTranscriptText }
            return TranscriptDelta(text: delta, isFinal: false)
        case "conversation.item.input_audio_transcription.completed":
            guard let transcript = event.transcript else { throw OpenAIRealtimeTranscriptionError.missingTranscriptText }
            return TranscriptDelta(text: transcript, isFinal: true)
        case "error":
            throw OpenAIRealtimeTranscriptionError.serverError(event.error?.message ?? "OpenAI realtime transcription failed.")
        default:
            throw OpenAIRealtimeTranscriptionError.unsupportedEvent(event.type)
        }
    }

    nonisolated static func makePCM16Data(fromMonoFloatSamples samples: [Float]) -> Data {
        var data = Data()
        data.reserveCapacity(samples.count * MemoryLayout<Int16>.size)

        for sample in samples {
            let clamped = min(1.0, max(-1.0, sample))
            let scaled = clamped < 0 ? clamped * 32768.0 : clamped * 32767.0
            var value = Int16(scaled.rounded(.towardZero)).littleEndian
            withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
        }

        return data
    }

    nonisolated static func makePCM16AudioData(from buffer: AVAudioPCMBuffer) throws -> Data {
        let targetSampleRate = 24_000.0
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
                throw OpenAIRealtimeTranscriptionError.audioConversionFailed("Unable to create audio converter.")
            }

            let ratio = targetSampleRate / buffer.format.sampleRate
            let frameCapacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else {
                throw OpenAIRealtimeTranscriptionError.audioConversionFailed("Unable to allocate converted audio buffer.")
            }

            let inputProvider = ConverterInputProvider(buffer: buffer)
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
                throw OpenAIRealtimeTranscriptionError.audioConversionFailed(reason)
            }
            monoBuffer = converted
        }

        guard let channel = monoBuffer.floatChannelData?[0] else {
            throw OpenAIRealtimeTranscriptionError.audioConversionFailed("Converted audio was not Float32 PCM.")
        }

        let sampleCount = Int(monoBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channel, count: sampleCount))
        return makePCM16Data(fromMonoFloatSamples: samples)
    }

    nonisolated private static func parseRecognizedDeltaEvent(_ data: Data) throws -> TranscriptDelta? {
        do {
            return try parseDeltaEvent(data)
        } catch OpenAIRealtimeTranscriptionError.unsupportedEvent {
            return nil
        }
    }

    private func connectAndStartAudio() async throws {
        guard lifecycleState == .connecting else { return }

        try startAudioCapture()

        var request = URLRequest(url: endpoint)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

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
                    if delta.isFinal {
                        complete()
                    }
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

    private func sendCommitAndWaitForCompletion() {
        stopAudioCapture()
        switch lifecycleState {
        case .finished:
            return
        case .stopping:
            return
        case .connecting, .listening:
            break
        }

        guard let webSocketClient else {
            finish(throwing: OpenAIRealtimeTranscriptionError.noActiveWebSocket)
            return
        }

        lifecycleState = .stopping

        Task { [weak self] in
            do {
                guard let self else { return }
                guard self.lifecycleState == .stopping else { return }
                let data = try self.makeCommitEventData()
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
            throw OpenAIRealtimeTranscriptionError.invalidOutboundMessage
        }

        try await (client ?? webSocketClient)?.send(.text(text))
    }

    private func startCommitTimeout() {
        commitTimeoutTask?.cancel()
        commitTimeoutTask = Task { [weak self] in
            do {
                guard let self else { return }
                try await Task.sleep(nanoseconds: self.commitTimeoutNanoseconds)
                self.finish(throwing: OpenAIRealtimeTranscriptionError.commitTimedOut)
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
}

extension OpenAIRealtimeTranscriptionProvider: RealtimeTranscriptionProvider {
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
        sendCommitAndWaitForCompletion()
    }

    func abort() {
        finish()
    }
}

enum OpenAIRealtimeTranscriptionError: LocalizedError, Equatable {
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
            return "OpenAI realtime returned unsupported event: \(type)"
        case .missingTranscriptText:
            return "OpenAI realtime transcription event did not include transcript text."
        case let .serverError(message):
            return "OpenAI realtime transcription failed: \(message)"
        case let .audioConversionFailed(message):
            return "Could not prepare microphone audio for OpenAI realtime transcription: \(message)"
        case .commitTimedOut:
            return "Timed out waiting for OpenAI realtime transcription to finish."
        case .noActiveWebSocket:
            return "Cannot commit OpenAI realtime transcription because no websocket is active."
        case .invalidOutboundMessage:
            return "Could not prepare the OpenAI realtime websocket message."
        }
    }
}

private enum LifecycleState {
    case connecting
    case listening
    case stopping
    case finished
}

private struct RealtimeServerEvent: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let type: String
    let delta: String?
    let transcript: String?
    let error: APIError?
}

private final class ConverterInputProvider: @unchecked Sendable {
    private var buffer: AVAudioPCMBuffer?

    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }

    func takeBuffer() -> AVAudioPCMBuffer? {
        defer { buffer = nil }
        return buffer
    }
}

@MainActor
protocol OpenAIRealtimeWebSocketFactory {
    func makeClient(request: URLRequest) -> OpenAIRealtimeWebSocketClient
}

@MainActor
protocol OpenAIRealtimeWebSocketClient: AnyObject {
    func resume()
    func send(_ message: OpenAIRealtimeWebSocketMessage) async throws
    func receive() async throws -> Data
    func cancel()
}

enum OpenAIRealtimeWebSocketMessage: Equatable {
    case text(String)

    var data: Data {
        switch self {
        case let .text(text):
            return Data(text.utf8)
        }
    }
}

private struct URLSessionOpenAIRealtimeWebSocketFactory: OpenAIRealtimeWebSocketFactory {
    let session: URLSession

    func makeClient(request: URLRequest) -> OpenAIRealtimeWebSocketClient {
        URLSessionOpenAIRealtimeWebSocketClient(task: session.webSocketTask(with: request))
    }
}

private final class URLSessionOpenAIRealtimeWebSocketClient: OpenAIRealtimeWebSocketClient {
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
