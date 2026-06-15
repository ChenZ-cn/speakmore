import Foundation

@MainActor
final class FailoverTextTransformProvider: TextTransformProvider {
    private let providers: [TextTransformProvider]

    init(providers: [TextTransformProvider]) {
        self.providers = providers
    }

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        var lastError: Error?

        for provider in providers {
            do {
                return try await provider.transform(input: input)
            } catch {
                lastError = error

                guard Self.shouldTryNextProvider(after: error) else {
                    throw error
                }
            }
        }

        throw lastError ?? FailoverProviderError.noProviders
    }

    private static func shouldTryNextProvider(after error: Error) -> Bool {
        if case let OpenAITextTransformError.httpStatus(statusCode, _) = error {
            return [401, 403, 429, 500, 502, 503, 504].contains(statusCode)
        }

        if error is URLError {
            return true
        }

        return false
    }
}
