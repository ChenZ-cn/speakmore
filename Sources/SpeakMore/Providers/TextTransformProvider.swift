import Foundation

@MainActor
protocol TextTransformProvider {
    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult
}
