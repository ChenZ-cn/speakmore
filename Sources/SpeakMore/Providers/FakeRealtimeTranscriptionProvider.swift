import Foundation

final class FakeRealtimeTranscriptionProvider: RealtimeTranscriptionProvider {
    private let deltas: [TranscriptDelta]
    private var continuation: AsyncThrowingStream<TranscriptDelta, Error>.Continuation?
    private var producerTask: Task<Void, Never>?

    init(deltas: [TranscriptDelta] = [
        TranscriptDelta(text: "This is a fake live transcript.", isFinal: true)
    ]) {
        self.deltas = deltas
    }

    func startTranscription() -> AsyncThrowingStream<TranscriptDelta, Error> {
        let deltas = deltas

        return AsyncThrowingStream { continuation in
            self.producerTask?.cancel()
            self.continuation = continuation
            self.producerTask = Task {
                for delta in deltas {
                    if Task.isCancelled { break }

                    do {
                        try await Task.sleep(nanoseconds: 80_000_000)
                    } catch {
                        break
                    }

                    if Task.isCancelled { break }
                    continuation.yield(delta)
                }

                continuation.finish()
            }

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.producerTask?.cancel()
                    self?.producerTask = nil
                    self?.continuation = nil
                }
            }
        }
    }

    func stop() {
        continuation?.finish()
    }

    func abort() {
        producerTask?.cancel()
        producerTask = nil
        continuation?.finish()
        continuation = nil
    }
}
