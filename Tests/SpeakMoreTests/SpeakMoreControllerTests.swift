import Combine
import XCTest
@testable import SpeakMore

final class SpeakMoreControllerTests: XCTestCase {
    @MainActor
    func testFakeSessionProducesFinalText() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "hello", isFinal: false), toSessionAt: 0)
        realtimeProvider.yield(TranscriptDelta(text: "hello world", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(state.rawTranscript, "hello world")
        XCTAssertEqual(state.finalText, "hello world")
        XCTAssertEqual(state.status, .idle)
    }

    @MainActor
    func testIncrementalDeltasAccumulateUntilCompletedTranscriptArrives() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.deltaAccumulation")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "Hello", isFinal: false), toSessionAt: 0)
        await waitForRawTranscript("Hello", state: state)

        realtimeProvider.yield(TranscriptDelta(text: ", world", isFinal: false), toSessionAt: 0)
        await waitForRawTranscript("Hello, world", state: state)

        realtimeProvider.yield(TranscriptDelta(text: "Hello, world", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(state.rawTranscript, "Hello, world")
        XCTAssertEqual(state.finalText, "Hello, world")
    }

    @MainActor
    func testReplacementDeltasRefreshCurrentTranscriptInsteadOfAppending() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.replacementDeltas")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "这次", isFinal: false, replacesPrevious: true), toSessionAt: 0)
        await waitForRawTranscript("这次", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "这次再试一下", isFinal: false, replacesPrevious: true), toSessionAt: 0)
        await waitForRawTranscript("这次再试一下", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "这次再试一下好使了吗？", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(state.rawTranscript, "这次再试一下好使了吗？")
        XCTAssertEqual(state.finalText, "这次再试一下好使了吗？")
    }

    @MainActor
    func testReplacementFinalSegmentsAccumulateAcrossAliyunUtterances() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.replacementSegments")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "端午节", isFinal: false, replacesPrevious: true), toSessionAt: 0)
        await waitForRawTranscript("端午节", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "端午节。", isFinal: true, replacesPrevious: true), toSessionAt: 0)
        await waitForRawTranscript("端午节。", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "中国农历的五月五日", isFinal: false, replacesPrevious: true), toSessionAt: 0)
        await waitForRawTranscript("端午节。中国农历的五月五日", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "中国农历的五月五日是一个重要的节日。", isFinal: true, replacesPrevious: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(state.rawTranscript, "端午节。中国农历的五月五日是一个重要的节日。")
        XCTAssertEqual(state.finalText, "端午节。中国农历的五月五日是一个重要的节日。")
    }

    @MainActor
    func testFinalSegmentsWithoutPunctuationAreSeparatedForReadability() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.unpunctuatedSegments")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "我觉得这个功能还不错", isFinal: true, replacesPrevious: true), toSessionAt: 0)
        await waitForRawTranscript("我觉得这个功能还不错", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "但是断句不太自然", isFinal: false, replacesPrevious: true), toSessionAt: 0)
        await waitForRawTranscript("我觉得这个功能还不错，但是断句不太自然", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "但是断句不太自然", isFinal: true, replacesPrevious: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(state.rawTranscript, "我觉得这个功能还不错，但是断句不太自然")
        XCTAssertEqual(state.finalText, "我觉得这个功能还不错，但是断句不太自然")
    }

    @MainActor
    func testSessionPastesFinalText() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.paste")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: " pasted words ", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(state.finalText, "pasted words")
        XCTAssertEqual(pasteSink.pastedTexts, ["pasted words"])
        XCTAssertEqual(pasteSink.draftReplacements, [])
    }

    @MainActor
    func testVoiceCommandRevertsLastSpeakMoreInsertionWithoutPastingCommand() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = CountingTextTransformProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.revertLastInsertion")!),
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "上一段文字", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(2, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "删掉刚才那段", isFinal: true), toSessionAt: 1)
        realtimeProvider.finishSession(at: 1)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(textProvider.transformCallCount, 1)
        XCTAssertEqual(pasteSink.pastedTexts, ["上一段文字"])
        XCTAssertEqual(pasteSink.revertLastPastedTextCallCount, 1)
    }

    @MainActor
    func testVoiceCommandRevertsLastSpeakMoreSentenceWithoutPastingCommand() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = CountingTextTransformProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.revertLastSentence")!),
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "第一句话。第二句话。", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(2, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "删除上一句话", isFinal: true), toSessionAt: 1)
        realtimeProvider.finishSession(at: 1)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(textProvider.transformCallCount, 1)
        XCTAssertEqual(pasteSink.pastedTexts, ["第一句话。第二句话。"])
        XCTAssertEqual(pasteSink.revertLastPastedSentenceCallCount, 1)
    }

    @MainActor
    func testVoiceCommandRevertsLastSpeakMoreSentenceWithNaturalRecentSentencePhrase() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = CountingTextTransformProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.revertRecentSentence")!),
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "第一句话。第二句话。", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(2, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "删除刚才那句话", isFinal: true), toSessionAt: 1)
        realtimeProvider.finishSession(at: 1)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(textProvider.transformCallCount, 1)
        XCTAssertEqual(pasteSink.pastedTexts, ["第一句话。第二句话。"])
        XCTAssertEqual(pasteSink.revertLastPastedSentenceCallCount, 1)
    }

    @MainActor
    func testVoiceCommandRevertsLastSpeakMoreSentenceWithVerboseNaturalPhrase() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = CountingTextTransformProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.revertVerboseRecentSentence")!),
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "第一句话。第二句话。", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(2, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "删除我输入的刚才输的那句话", isFinal: true), toSessionAt: 1)
        realtimeProvider.finishSession(at: 1)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(textProvider.transformCallCount, 1)
        XCTAssertEqual(pasteSink.pastedTexts, ["第一句话。第二句话。"])
        XCTAssertEqual(pasteSink.revertLastPastedSentenceCallCount, 1)
    }

    @MainActor
    func testStaleSessionCannotOverwriteNewerSession() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.stale")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "old transcript", isFinal: true), toSessionAt: 0)

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(2, realtimeProvider: realtimeProvider)
        XCTAssertEqual(realtimeProvider.abortCallCount, 1)
        XCTAssertEqual(state.rawTranscript, "")
        XCTAssertEqual(state.status, .listening)

        realtimeProvider.finishSession(at: 0)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(state.rawTranscript, "")
        XCTAssertEqual(state.finalText, "")
        XCTAssertEqual(state.status, .listening)
    }

    @MainActor
    func testStopSessionFinalizesCurrentSession() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.stop")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)

        controller.stopSession()
        XCTAssertEqual(realtimeProvider.stopCallCount, 1)
        XCTAssertEqual(state.status, .finalizing)

        realtimeProvider.yield(TranscriptDelta(text: "final transcript", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(state.rawTranscript, "final transcript")
        XCTAssertEqual(state.finalText, "final transcript")
        XCTAssertEqual(state.status, .idle)
    }

    @MainActor
    func testStopSessionShowsAITransformingStatusBeforePasting() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = SuspendingTextTransformProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.transforming")!),
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)

        controller.stopSession()
        XCTAssertEqual(state.status, .finalizing)

        realtimeProvider.yield(TranscriptDelta(text: "rough words", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForTransformRequest(textProvider)

        XCTAssertEqual(state.status, .transforming)

        textProvider.finish(
            with: VoiceSessionResult(
                rawTranscript: "rough words",
                finalText: "clean words",
                shouldReplaceSelection: false
            )
        )
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(pasteSink.pastedTexts, ["clean words"])
        XCTAssertEqual(pasteSink.draftReplacements, [])
    }

    @MainActor
    func testDictationDoesNotWriteInterimTextIntoActiveInputField() async throws {
        let defaults = UserDefaults(suiteName: "SpeakMoreControllerTests.noLiveDraft")!
        defaults.removePersistentDomain(forName: "SpeakMoreControllerTests.noLiveDraft")
        let settings = AppSettings(defaults: defaults)
        settings.defaultMode = .dictate
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = FixedTextTransformProvider(finalText: "整理好的文字")
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "草稿", isFinal: false), toSessionAt: 0)
        await waitForRawTranscript("草稿", state: state)
        realtimeProvider.yield(TranscriptDelta(text: "草稿文字", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(pasteSink.draftReplacements, [])
        XCTAssertEqual(pasteSink.pastedTexts, ["整理好的文字"])
    }

    @MainActor
    func testTranslationModeDoesNotLiveDraftSourceText() async throws {
        let defaults = UserDefaults(suiteName: "SpeakMoreControllerTests.noLiveDraftForTranslate")!
        defaults.removePersistentDomain(forName: "SpeakMoreControllerTests.noLiveDraftForTranslate")
        let settings = AppSettings(defaults: defaults)
        settings.defaultMode = .translate
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: realtimeProvider,
            textProvider: FixedTextTransformProvider(finalText: "final translation"),
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "源文本", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(pasteSink.draftReplacements, [])
        XCTAssertEqual(pasteSink.pastedTexts, ["final translation"])
    }

    @MainActor
    func testSessionModeCanSwitchBeforeFinalTransform() async throws {
        let defaults = UserDefaults(suiteName: "SpeakMoreControllerTests.modeSwitch")!
        defaults.removePersistentDomain(forName: "SpeakMoreControllerTests.modeSwitch")
        let settings = AppSettings(defaults: defaults)
        settings.defaultMode = .auto
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = SuspendingTextTransformProvider()
        let pasteSink = CapturingPasteSink()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)

        controller.switchMode(.translate)
        XCTAssertEqual(state.mode, .translate)
        XCTAssertEqual(settings.defaultMode, .auto)

        realtimeProvider.yield(TranscriptDelta(text: "帮我回复一下", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForTransformRequest(textProvider)

        XCTAssertEqual(textProvider.latestInput?.mode, .translate)

        textProvider.finish(
            with: VoiceSessionResult(
                rawTranscript: "帮我回复一下",
                finalText: "Help me reply.",
                shouldReplaceSelection: false
            )
        )
        await waitForStatus(.idle, state: state)

        XCTAssertEqual(pasteSink.pastedTexts, ["Help me reply."])
    }

    @MainActor
    func testOfflineBeforeStartShowsNetworkErrorWithoutStartingProvider() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.offlineBeforeStart")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink(),
            networkAvailabilityChecker: FixedNetworkAvailabilityChecker(isNetworkAvailable: false)
        )

        await controller.startSession(selectedText: nil)
        await Task.yield()

        XCTAssertEqual(realtimeProvider.sessionCount, 0)
        XCTAssertEqual(state.status, .failed("当前网络不可用，请联网后再试。"))
        XCTAssertEqual(state.errorMessage, "当前网络不可用，请联网后再试。")
    }

    @MainActor
    func testNetworkFailureAfterPartialTranscriptPastesRecognizedTextAndShowsWarning() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let pasteSink = CapturingPasteSink()
        let textProvider = CountingTextTransformProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.offlineAfterSpeech")!),
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink,
            networkAvailabilityChecker: FixedNetworkAvailabilityChecker(isNetworkAvailable: true)
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "前半段已经识别出来", isFinal: false), toSessionAt: 0)
        await waitForRawTranscript("前半段已经识别出来", state: state)

        realtimeProvider.finishSession(at: 0, throwing: URLError(.notConnectedToInternet))
        await waitForStatus(.failed("网络异常，已插入已识别的内容，请检查网络后再试。"), state: state)

        XCTAssertEqual(textProvider.transformCallCount, 0)
        XCTAssertEqual(pasteSink.pastedTexts, ["前半段已经识别出来"])
        XCTAssertEqual(state.finalText, "前半段已经识别出来")
        XCTAssertEqual(state.errorMessage, "网络异常，已插入已识别的内容，请检查网络后再试。")
    }

    @MainActor
    func testNetworkFailureBeforeAnyTranscriptShowsFriendlyNetworkError() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.networkNoTranscript")!),
            realtimeProvider: realtimeProvider,
            textProvider: CountingTextTransformProvider(),
            pasteSink: CapturingPasteSink(),
            networkAvailabilityChecker: FixedNetworkAvailabilityChecker(isNetworkAvailable: true)
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)

        realtimeProvider.finishSession(at: 0, throwing: URLError(.notConnectedToInternet))
        await waitForStatus(.failed("网络异常，请检查网络后再试。"), state: state)

        XCTAssertEqual(state.errorMessage, "网络异常，请检查网络后再试。")
    }

    @MainActor
    func testSelectedTextCanBeUpdatedAfterAudioSessionStarts() async throws {
        let defaults = UserDefaults(suiteName: "SpeakMoreControllerTests.selectedTextUpdate")!
        defaults.removePersistentDomain(forName: "SpeakMoreControllerTests.selectedTextUpdate")
        let settings = AppSettings(defaults: defaults)
        settings.defaultMode = .askSelectedText
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = SuspendingTextTransformProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: CapturingPasteSink()
        )

        let generation = await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)

        controller.updateSelectedText("当前选中的 Slack 消息", for: generation)
        XCTAssertEqual(state.selectedText, "当前选中的 Slack 消息")

        realtimeProvider.yield(TranscriptDelta(text: "你会怎么答？", isFinal: true), toSessionAt: 0)
        realtimeProvider.finishSession(at: 0)
        await waitForTransformRequest(textProvider)

        XCTAssertEqual(textProvider.latestInput?.mode, .askSelectedText)
        XCTAssertEqual(textProvider.latestInput?.selectedText, "当前选中的 Slack 消息")

        textProvider.finish(
            with: VoiceSessionResult(
                rawTranscript: "你会怎么答？",
                finalText: "我会这样回复。",
                shouldReplaceSelection: true
            )
        )
        await waitForStatus(.idle, state: state)
    }

    @MainActor
    func testSelectedTextUpdateIgnoresStaleSessionGeneration() async throws {
        let defaults = UserDefaults(suiteName: "SpeakMoreControllerTests.staleSelectedTextUpdate")!
        defaults.removePersistentDomain(forName: "SpeakMoreControllerTests.staleSelectedTextUpdate")
        let settings = AppSettings(defaults: defaults)
        settings.defaultMode = .askSelectedText
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        let firstGeneration = await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)

        _ = await controller.startSession(selectedText: nil)
        await waitForSessionCount(2, realtimeProvider: realtimeProvider)

        controller.updateSelectedText("旧会话选区", for: firstGeneration)

        XCTAssertNil(state.selectedText)
    }

    @MainActor
    func testEmptyTranscriptDismissesWithoutShowingNoSpeechState() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let textProvider = CountingTextTransformProvider()
        let pasteSink = CapturingPasteSink()
        var observedStatuses: [SpeakMoreSessionStatus] = []
        let cancellable = state.$status.sink { status in
            observedStatuses.append(status)
        }
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.empty")!),
            realtimeProvider: realtimeProvider,
            textProvider: textProvider,
            pasteSink: pasteSink
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        controller.stopSession()
        realtimeProvider.finishSession(at: 0)
        await waitForStatus(.idle, state: state)

        XCTAssertNil(state.errorMessage)
        XCTAssertFalse(observedStatuses.contains(.noSpeech))
        XCTAssertEqual(textProvider.transformCallCount, 0)
        XCTAssertEqual(pasteSink.pastedTexts, [])
        cancellable.cancel()
    }

    @MainActor
    func testCancelSessionAbortsCurrentSessionAndResetsState() async throws {
        let state = AppState()
        let realtimeProvider = ManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: AppSettings(defaults: UserDefaults(suiteName: "SpeakMoreControllerTests.cancel")!),
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: CapturingPasteSink()
        )

        await controller.startSession(selectedText: nil)
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        realtimeProvider.yield(TranscriptDelta(text: "partial", isFinal: false), toSessionAt: 0)
        await Task.yield()

        controller.cancelSession()

        XCTAssertEqual(realtimeProvider.abortCallCount, 1)
        XCTAssertEqual(state.rawTranscript, "")
        XCTAssertEqual(state.finalText, "")
        XCTAssertEqual(state.errorMessage, nil)
        XCTAssertEqual(state.status, .idle)
    }

    @MainActor
    private func waitForRawTranscript(
        _ expectedTranscript: String,
        state: AppState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where state.rawTranscript != expectedTranscript {
            await Task.yield()
        }

        XCTAssertEqual(state.rawTranscript, expectedTranscript, file: file, line: line)
    }

    @MainActor
    private func waitForStatus(
        _ expectedStatus: SpeakMoreSessionStatus,
        state: AppState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where state.status != expectedStatus {
            await Task.yield()
        }

        XCTAssertEqual(state.status, expectedStatus, file: file, line: line)
    }

    @MainActor
    private func waitForSessionCount(
        _ expectedCount: Int,
        realtimeProvider: ManualRealtimeTranscriptionProvider,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where realtimeProvider.sessionCount < expectedCount {
            await Task.yield()
        }

        XCTAssertGreaterThanOrEqual(realtimeProvider.sessionCount, expectedCount, file: file, line: line)
    }

    @MainActor
    private func waitForTransformRequest(
        _ textProvider: SuspendingTextTransformProvider,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await textProvider.waitForRequest()
        XCTAssertNotNil(textProvider.latestInput, file: file, line: line)
    }
}

@MainActor
private struct FixedNetworkAvailabilityChecker: NetworkAvailabilityChecking {
    let isNetworkAvailable: Bool
}

@MainActor
private final class CapturingPasteSink: PasteTextSink {
    private(set) var pastedTexts: [String] = []
    private(set) var draftReplacements: [DraftReplacement] = []
    private(set) var revertLastPastedTextCallCount = 0
    private(set) var revertLastPastedSentenceCallCount = 0

    func paste(text: String) throws {
        pastedTexts.append(text)
    }

    func revertLastPastedText() throws -> Bool {
        revertLastPastedTextCallCount += 1
        return true
    }

    func revertLastPastedSentence() throws -> Bool {
        revertLastPastedSentenceCallCount += 1
        return true
    }
}

private struct DraftReplacement: Equatable {
    let previousText: String
    let newText: String
}

@MainActor
private final class SuspendingTextTransformProvider: TextTransformProvider {
    private var requestContinuation: CheckedContinuation<Void, Never>?
    private var resultContinuation: CheckedContinuation<VoiceSessionResult, Never>?
    private(set) var latestInput: VoiceSessionInput?

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        latestInput = input
        requestContinuation?.resume()
        requestContinuation = nil
        return await withCheckedContinuation { continuation in
            resultContinuation = continuation
        }
    }

    func waitForRequest() async {
        if latestInput != nil {
            return
        }

        await withCheckedContinuation { continuation in
            requestContinuation = continuation
        }
    }

    func finish(with result: VoiceSessionResult) {
        resultContinuation?.resume(returning: result)
        resultContinuation = nil
    }
}

@MainActor
private final class CountingTextTransformProvider: TextTransformProvider {
    private(set) var transformCallCount = 0

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        transformCallCount += 1
        return VoiceSessionResult(
            rawTranscript: input.rawTranscript,
            finalText: input.rawTranscript,
            shouldReplaceSelection: false
        )
    }
}

@MainActor
private final class FixedTextTransformProvider: TextTransformProvider {
    private let finalText: String

    init(finalText: String) {
        self.finalText = finalText
    }

    func transform(input: VoiceSessionInput) async throws -> VoiceSessionResult {
        VoiceSessionResult(
            rawTranscript: input.rawTranscript,
            finalText: finalText,
            shouldReplaceSelection: false
        )
    }
}

private final class ManualRealtimeTranscriptionProvider: RealtimeTranscriptionProvider {
    private var continuations: [AsyncThrowingStream<TranscriptDelta, Error>.Continuation] = []
    private(set) var stopCallCount = 0
    private(set) var abortCallCount = 0

    var sessionCount: Int {
        continuations.count
    }

    func startTranscription() -> AsyncThrowingStream<TranscriptDelta, Error> {
        AsyncThrowingStream { continuation in
            continuations.append(continuation)
        }
    }

    func stop() {
        stopCallCount += 1
    }

    func abort() {
        abortCallCount += 1
    }

    func yield(_ delta: TranscriptDelta, toSessionAt index: Int) {
        continuations[index].yield(delta)
    }

    func finishSession(at index: Int) {
        continuations[index].finish()
    }

    func finishSession(at index: Int, throwing error: Error) {
        continuations[index].finish(throwing: error)
    }
}
