import XCTest
@testable import SpeakMore

final class TextTransformPromptBuilderTests: XCTestCase {
    func testAutoPromptDetectsChatStructuredFormalAndEnglishCorrectionNeeds() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "first we need deploy then tell Alex this are ready",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("choose the best output shape"))
        XCTAssertTrue(prompt.system.contains("chat reply"))
        XCTAssertTrue(prompt.system.contains("structured list"))
        XCTAssertTrue(prompt.system.contains("formal message"))
        XCTAssertTrue(prompt.system.contains("Fix English grammar"))
        XCTAssertTrue(prompt.system.contains("Do not add new meaning"))
        XCTAssertTrue(prompt.user.contains("this are ready"))
    }

    func testDictatePromptRemovesFillersWithoutAddingMeaning() {
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "um tell Alex I I can meet tomorrow",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("clean written text"))
        XCTAssertTrue(prompt.system.contains("Fix English grammar"))
        XCTAssertTrue(prompt.system.contains("Do not add new meaning"))
        XCTAssertTrue(prompt.user.contains("um tell Alex"))
    }

    func testAutoPromptAppliesSpokenEditingInstructionsToEarlierContent() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "哎我想试一下。你把所有文字都删掉，只保留第一个字",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("spoken editing instruction"))
        XCTAssertTrue(prompt.system.contains("apply the instruction to the earlier content"))
        XCTAssertTrue(prompt.system.contains("do not include the instruction itself"))
        XCTAssertTrue(prompt.system.contains("帮我整理成一句话"))
    }

    func testAutoPromptUsesInputMethodStyleChineseCleanupAndLineBreaks() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "对了现在还有一条目前框只能显示三行我希望它可以变长好不好",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("Correct obvious Chinese typos"))
        XCTAssertTrue(prompt.system.contains("minor word-order issues"))
        XCTAssertTrue(prompt.system.contains("Use paragraph breaks"))
        XCTAssertTrue(prompt.system.contains("light structure or summarize"))
        XCTAssertTrue(prompt.system.contains("Do not over-summarize short chat messages"))
    }

    func testAutoPromptForbidsUnrequestedTranslationOfMixedChineseText() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "慢速中文。Slow Chinese.今天你Q了吗？中国人喜欢用QQ聊天。",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("Never translate Chinese text into English unless"))
        XCTAssertTrue(prompt.system.contains("remove ASR artifacts"))
        XCTAssertTrue(prompt.system.contains("music symbols"))
        XCTAssertTrue(prompt.system.contains("Do not drop meaningful Chinese comments"))
    }

    func testAutoPromptKeepsAllMeaningfulSentencesWhenNoCommandIsSeparated() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "The target language is not fixed as English. 你看，这句话不应该翻译。",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("If spoken_command is null"))
        XCTAssertTrue(prompt.system.contains("keep every meaningful sentence"))
        XCTAssertTrue(prompt.system.contains("preservation task"))
        XCTAssertTrue(prompt.system.contains("mention translation"))
        XCTAssertTrue(prompt.user.contains("\"raw_transcript\""))
        XCTAssertTrue(prompt.user.contains("No separate spoken command"))
    }

    func testPromptUsesSeparatedSpokenCommandAsInstructionOnly() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "我明天下午可以开会。",
            selectedText: nil,
            spokenCommand: "翻译成日语。",
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("A spoken_command field may be provided separately"))
        XCTAssertTrue(prompt.system.contains("Never include the command text itself"))
        XCTAssertTrue(prompt.user.contains("\"content_transcript\""))
        XCTAssertTrue(prompt.user.contains("我明天下午可以开会。"))
        XCTAssertTrue(prompt.user.contains("\"spoken_command\""))
        XCTAssertTrue(prompt.user.contains("翻译成日语。"))
    }

    func testAutoPromptDoesNotLeakDefaultTargetLanguageIntoNonTranslationCommands() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "我们先修语音识别，再优化 UI，最后发一个新版。",
            selectedText: nil,
            spokenCommand: "帮我分点整理一下。",
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.user.contains("\"mode\" : \"auto\""))
        XCTAssertFalse(prompt.user.contains("\"target_language\""))
        XCTAssertTrue(prompt.user.contains("帮我分点整理一下。"))
    }

    func testStrongPolishIntensityAllowsMoreStructure() {
        let input = VoiceSessionInput(
            mode: .auto,
            rawTranscript: "帮我整理一下这个事情",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder(intensity: .strong).build(input: input)

        XCTAssertTrue(prompt.system.contains("Use stronger cleanup"))
        XCTAssertTrue(prompt.system.contains("more structure"))
    }

    func testDictatePromptSupportsMixedLanguageInputMethodBehavior() {
        let input = VoiceSessionInput(
            mode: .dictate,
            rawTranscript: "帮我 reply Alex 说明天 ship v2",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("Preserve the intended language"))
        XCTAssertTrue(prompt.system.contains("Correct obvious speech recognition errors conservatively"))
        XCTAssertTrue(prompt.system.contains("ready to send"))
        XCTAssertTrue(prompt.system.contains("short fragments"))
        XCTAssertTrue(prompt.system.contains("without inventing missing context"))
        XCTAssertFalse(prompt.system.contains("WeChat"))
        XCTAssertFalse(prompt.system.contains("Doubao"))
        XCTAssertTrue(prompt.user.contains("帮我 reply Alex"))
    }

    func testTranslatePromptUsesTargetLanguage() {
        let input = VoiceSessionInput(
            mode: .translate,
            rawTranscript: "我明天可以参加会议",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("native-sounding English"))
        XCTAssertTrue(prompt.system.contains("Preserve names, product names, numbers, and code-like text"))
        XCTAssertTrue(prompt.user.contains("我明天可以参加会议"))
    }

    func testTranslatePromptCleansChineseStructureBeforeTranslating() {
        let input = VoiceSessionInput(
            mode: .translate,
            rawTranscript: "呃我觉得这个方案吧就是它可能不太那个但是核心意思是我们明天先发一个小版本",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("First clean and clarify the Chinese source meaning"))
        XCTAssertTrue(prompt.system.contains("remove filler words, false starts, obvious repetition"))
        XCTAssertTrue(prompt.system.contains("do not translate speech recognition mistakes or broken wording literally"))
        XCTAssertTrue(prompt.system.contains("Then translate the cleaned meaning"))
    }

    func testPolishPromptKeepsToneWithoutOverFormalizing() {
        let input = VoiceSessionInput(
            mode: .polish,
            rawTranscript: "hi Alex 我觉得 this API 可能有点 weird",
            selectedText: nil,
            spokenCommand: nil,
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("Keep the user's tone"))
        XCTAssertTrue(prompt.system.contains("not overly formal"))
        XCTAssertTrue(prompt.system.contains("Preserve the intended language"))
        XCTAssertTrue(prompt.system.contains("Correct obvious speech recognition errors conservatively"))
        XCTAssertTrue(prompt.system.contains("short fragments"))
        XCTAssertTrue(prompt.system.contains("without inventing missing context"))
        XCTAssertFalse(prompt.system.contains("WeChat"))
        XCTAssertFalse(prompt.system.contains("Doubao"))
        XCTAssertTrue(prompt.user.contains("this API"))
    }

    func testAskSelectedTextPromptIncludesSelectionAndCommand() {
        let input = VoiceSessionInput(
            mode: .askSelectedText,
            rawTranscript: "summarize this in three bullets",
            selectedText: "A long product update",
            spokenCommand: "summarize this in three bullets",
            targetLanguage: "English"
        )

        let prompt = TextTransformPromptBuilder().build(input: input)

        XCTAssertTrue(prompt.system.contains("selected text"))
        XCTAssertTrue(prompt.user.contains("A long product update"))
        XCTAssertTrue(prompt.user.contains("summarize this in three bullets"))
    }
}
