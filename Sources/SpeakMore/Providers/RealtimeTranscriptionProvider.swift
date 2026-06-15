import Foundation

@MainActor
protocol RealtimeTranscriptionProvider {
    func startTranscription() -> AsyncThrowingStream<TranscriptDelta, Error>
    func stop()
    func abort()
}
