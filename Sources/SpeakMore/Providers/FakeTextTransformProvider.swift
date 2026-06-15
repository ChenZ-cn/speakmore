import Foundation

struct FakeTextTransformProvider: TextTransformProvider {
    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        VoiceSessionResult(
            rawTranscript: input.rawTranscript,
            finalText: input.rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines),
            shouldReplaceSelection: input.mode == .askSelectedText
        )
    }
}
