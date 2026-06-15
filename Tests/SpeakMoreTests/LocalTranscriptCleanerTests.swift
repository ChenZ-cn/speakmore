import XCTest
@testable import SpeakMore

@MainActor
final class LocalTranscriptCleanerTests: XCTestCase {
    func testSimpleChineseAcknowledgementCanSkipRemoteAI() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "  嗯，好的。  ",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let result = LocalTranscriptCleaner().fastResult(input: input)

        XCTAssertEqual(result?.finalText, "好的。")
    }

    func testUnpunctuatedChineseDictationUsesRemoteAIForPunctuation() {
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "这个断句不太好",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        XCTAssertNil(LocalTranscriptCleaner().fastResult(input: input))
    }

    func testEnglishSentenceWithLikelyGrammarIssueStillUsesRemoteAI() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "this are ready",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        XCTAssertNil(LocalTranscriptCleaner().fastResult(input: input))
    }

    func testTrailingInstructionCanKeepOnlyFirstCharacterOfSpokenContent() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "哎我想试一下有没有可能我说的话你能理解啊。你把所有的文字都删了，只保留第一个字",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let result = LocalTranscriptCleaner().fastResult(input: input)

        XCTAssertEqual(result?.finalText, "哎")
    }

    func testASRMusicArtifactsAreRemovedBeforeRemoteTransform() async throws {
        let remoteProvider = CapturingRemoteTextTransformProvider()
        let provider = FastPathTextTransformProvider(remoteProvider: remoteProvider)
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "🎼 慢速中文。🎼Slow Chinese.今天你Q了吗？中国人喜欢在网上聊天，现在最流行的聊天软件叫做QQ。",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        _ = try await provider.transform(input: input)

        XCTAssertEqual(remoteProvider.latestInput?.rawTranscript, "慢速中文。Slow Chinese.今天你Q了吗？中国人喜欢在网上聊天，现在最流行的聊天软件叫做QQ。")
    }

    func testRemoteInputSegmentsLongUnpunctuatedChineseSpeech() async throws {
        let remoteProvider = CapturingRemoteTextTransformProvider()
        let provider = FastPathTextTransformProvider(remoteProvider: remoteProvider)
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "我觉得第一确实挺好的但是现在这个东西你打算怎么做呢第二个也不错第三个你就自己记忆让他在后台里面设置第四的话我觉得也挺好",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        _ = try await provider.transform(input: input)

        XCTAssertEqual(
            remoteProvider.latestInput?.rawTranscript,
            "我觉得第一确实挺好的。但是现在这个东西你打算怎么做呢。第二个也不错。第三个你就自己记忆让他在后台里面设置。第四的话我觉得也挺好。"
        )
    }

    func testFinalEnglishTranslateCommandIsSeparatedFromContent() async throws {
        let remoteProvider = CapturingRemoteTextTransformProvider()
        let provider = FastPathTextTransformProvider(remoteProvider: remoteProvider)
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "This is much better. Please translate this sentence into English for me. I still want to try this sentence out. Translate it into English.",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        _ = try await provider.transform(input: input)

        XCTAssertEqual(remoteProvider.latestInput?.rawTranscript, "This is much better. I still want to try this sentence out.")
        XCTAssertEqual(remoteProvider.latestInput?.spokenCommand, "Translate it into English.")
    }

    func testChineseTranslateCommandKeepsTargetLanguageFromFinalCommand() async throws {
        let remoteProvider = CapturingRemoteTextTransformProvider()
        let provider = FastPathTextTransformProvider(remoteProvider: remoteProvider)
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "我明天下午可以开会。翻译成日语。",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        _ = try await provider.transform(input: input)

        XCTAssertEqual(remoteProvider.latestInput?.rawTranscript, "我明天下午可以开会。")
        XCTAssertEqual(remoteProvider.latestInput?.spokenCommand, "翻译成日语。")
    }

    func testBulletAndPolishCommandsAreSeparatedFromContent() async throws {
        let remoteProvider = CapturingRemoteTextTransformProvider()
        let provider = FastPathTextTransformProvider(remoteProvider: remoteProvider)
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "我们先修语音识别，再优化 UI，最后发一个新版。帮我分点整理一下。",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        _ = try await provider.transform(input: input)

        XCTAssertEqual(remoteProvider.latestInput?.rawTranscript, "我们先修语音识别，再优化 UI，最后发一个新版。")
        XCTAssertEqual(remoteProvider.latestInput?.spokenCommand, "帮我分点整理一下。")
    }

    func testTranslationNeverSkipsRemoteAI() {
        let input = VoiceSessionInput(
            mode: .translate,
            rawTranscript: "好的",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        XCTAssertNil(LocalTranscriptCleaner().fastResult(input: input))
    }
}

@MainActor
private final class CapturingRemoteTextTransformProvider: TextTransformProvider {
    private(set) var latestInput: VoiceSessionInput?

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        latestInput = input
        return VoiceSessionResult(
            rawTranscript: input.rawTranscript,
            finalText: input.rawTranscript,
            shouldReplaceSelection: false
        )
    }
}
