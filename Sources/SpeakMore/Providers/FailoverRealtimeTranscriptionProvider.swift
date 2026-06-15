import Foundation

@MainActor
final class FailoverRealtimeTranscriptionProvider: RealtimeTranscriptionProvider {
    private let providers: [RealtimeTranscriptionProvider]
    private var activeProvider: RealtimeTranscriptionProvider?
    private var streamTask: Task<Void, Never>?

    init(providers: [RealtimeTranscriptionProvider]) {
        self.providers = providers
    }

    func startTranscription() -> AsyncThrowingStream<TranscriptDelta, Error> {
        AsyncThrowingStream { continuation in
            self.abort()

            streamTask = Task { @MainActor in
                var lastError: Error?

                for provider in providers {
                    activeProvider = provider
                    var yieldedAnyTranscript = false

                    do {
                        for try await delta in provider.startTranscription() {
                            yieldedAnyTranscript = true
                            continuation.yield(delta)
                        }

                        activeProvider = nil
                        continuation.finish()
                        return
                    } catch {
                        provider.abort()
                        lastError = error

                        guard !yieldedAnyTranscript, Self.shouldTryNextProvider(after: error) else {
                            activeProvider = nil
                            continuation.finish(throwing: error)
                            return
                        }
                    }
                }

                activeProvider = nil
                continuation.finish(throwing: lastError ?? FailoverProviderError.noProviders)
            }

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.abort()
                }
            }
        }
    }

    func stop() {
        activeProvider?.stop()
    }

    func abort() {
        streamTask?.cancel()
        streamTask = nil
        activeProvider?.abort()
        activeProvider = nil
    }

    private static func shouldTryNextProvider(after error: Error) -> Bool {
        if case OpenAIRealtimeTranscriptionError.serverError = error {
            return true
        }

        if error is URLError {
            return true
        }

        return false
    }
}

enum FailoverProviderError: LocalizedError, Equatable {
    case noProviders

    var errorDescription: String? {
        switch self {
        case .noProviders:
            return "No OpenAI providers are configured."
        }
    }
}
