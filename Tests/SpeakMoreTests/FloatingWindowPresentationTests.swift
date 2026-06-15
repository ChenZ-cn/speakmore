import AppKit
import XCTest
@testable import SpeakMore

@MainActor
final class FloatingWindowPresentationTests: XCTestCase {
    func testFailedAccessibilityErrorShowsCloseAndSettingsActions() {
        let state = AppState()
        state.status = .failed("SpeakMore 需要辅助功能权限，才能把整理后的文字粘贴到当前输入框。")
        state.errorMessage = "SpeakMore 需要辅助功能权限，才能把整理后的文字粘贴到当前输入框。"

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.statusText, "需要处理")
        XCTAssertEqual(presentation.primaryActionTitle, "关闭")
        XCTAssertEqual(presentation.secondaryActionTitle, "打开辅助功能设置")
    }

    func testListeningStateShowsCancelAction() {
        let state = AppState()
        state.status = .listening

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.statusText, "说话中")
        XCTAssertEqual(presentation.primaryActionTitle, "取消")
        XCTAssertEqual(presentation.shortcutHint, "1 自动  2 直写  3 翻译  4 润色")
        XCTAssertNil(presentation.secondaryActionTitle)
    }

    func testPreferredSizeStartsAtThreeTextLinesWithSeparateShadowSurface() {
        let state = AppState()
        state.status = .listening

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(FloatingWindowPresentation.panelWidth, FloatingWindowPresentation.cardWidth)
        XCTAssertEqual(FloatingWindowPresentation.minimumPanelHeight, FloatingWindowPresentation.minimumCardHeight)
        XCTAssertEqual(presentation.preferredSize.width, FloatingWindowPresentation.panelWidth)
        XCTAssertGreaterThan(presentation.preferredSize.height, FloatingWindowPresentation.minimumPanelHeight)
        XCTAssertEqual(FloatingWindowPresentation.minimumTextLineCount, 3)
    }

    func testInitialPanelSizeStartsCompactWithSeparateShadowSurface() {
        XCTAssertEqual(FloatingWindowPresentation.initialPanelSize.width, FloatingWindowPresentation.panelWidth)
        XCTAssertEqual(FloatingWindowPresentation.initialPanelSize.height, FloatingWindowPresentation.minimumPanelHeight)
    }

    func testFloatingPanelUsesLargeLighterSeparateShadow() {
        XCTAssertGreaterThanOrEqual(FloatingWindowPresentation.shadowOutset, 40)
        XCTAssertLessThanOrEqual(FloatingWindowPresentation.shadowOpacity, 0.10)
        XCTAssertGreaterThanOrEqual(FloatingWindowPresentation.shadowRadius, 28)
        XCTAssertLessThan(FloatingWindowPresentation.borderStrokeOpacity, 0.08)
        XCTAssertEqual(FloatingWindowPresentation.initialPanelSize.height, FloatingWindowPresentation.minimumPanelHeight)
    }

    func testInitialVisibleCardHeightUsesCompactThreeLineHeight() {
        let state = AppState()
        state.status = .listening

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertGreaterThan(presentation.visibleCardHeight, FloatingWindowPresentation.minimumCardHeight)
    }

    func testVisibleCardHeightStaysCompactUntilTranscriptExceedsThreeLines() {
        let shortState = AppState()
        shortState.status = .listening
        shortState.rawTranscript = "短输入。"

        let shortPresentation = FloatingWindowPresentation(state: shortState)

        XCTAssertGreaterThan(shortPresentation.visibleCardHeight, FloatingWindowPresentation.minimumCardHeight)
        XCTAssertLessThan(shortPresentation.visibleCardHeight, 220)
    }

    func testVisibleCardHeightGrowsWhenListeningTranscriptExceedsThreeLines() {
        let shortState = AppState()
        shortState.status = .listening
        shortState.rawTranscript = "短输入。"

        let longState = AppState()
        longState.status = .listening
        longState.rawTranscript = Array(repeating: "这是一段更长的实时识别文字，会超过三行之后让输入框自然变高。", count: 16).joined()

        let shortPresentation = FloatingWindowPresentation(state: shortState)
        let longPresentation = FloatingWindowPresentation(state: longState)

        XCTAssertGreaterThan(shortPresentation.visibleCardHeight, FloatingWindowPresentation.minimumCardHeight)
        XCTAssertGreaterThan(longPresentation.visibleCardHeight, shortPresentation.visibleCardHeight)
        XCTAssertLessThanOrEqual(longPresentation.visibleCardHeight, FloatingWindowPresentation.maximumCardHeight)
        XCTAssertEqual(longPresentation.shadowCardHeight, longPresentation.visibleCardHeight)
    }

    func testEnglishFailedAccessibilityErrorLocalizesSecondaryAction() {
        let state = AppState()
        state.status = .failed("Accessibility permission is required")
        state.errorMessage = "Accessibility permission is required"

        let presentation = FloatingWindowPresentation(state: state, language: .english)

        XCTAssertEqual(presentation.statusText, "Needs Attention")
        XCTAssertEqual(presentation.primaryActionTitle, "Close")
        XCTAssertEqual(presentation.secondaryActionTitle, "Open Accessibility Settings")
    }

    func testQuotaErrorShowsModelSettingsAction() {
        let state = AppState()
        state.status = .failed("HTTP 429: insufficient quota")
        state.errorMessage = "HTTP 429: insufficient quota"

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.secondaryActionTitle, "打开模型设置")
    }

    func testNoSpeechStateIsNotPresentedAsFailure() {
        let state = AppState()
        state.status = .noSpeech

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.statusText, "无输入")
        XCTAssertEqual(presentation.primaryMessage, "没有检测到输入，稍后自动关闭。")
        XCTAssertEqual(presentation.primaryActionTitle, "关闭")
        XCTAssertNil(presentation.secondaryActionTitle)
    }

    func testInsertingStateIsNotPresentedAsUserVisibleStatus() {
        let state = AppState()
        state.status = .inserting

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.statusText, "就绪")
        XCTAssertEqual(presentation.primaryMessage, "准备好了")
        XCTAssertEqual(presentation.primaryActionTitle, "关闭")
    }

    func testLongTranscriptGrowsPanelHeightBeforeMaximum() {
        let shortState = AppState()
        shortState.status = .listening
        shortState.rawTranscript = "这是一句短输入。"

        let longState = AppState()
        longState.status = .listening
        longState.rawTranscript = Array(repeating: "这是一段更长的语音输入，需要让浮窗自动变高，而不是只显示三行。", count: 12).joined()

        let shortPresentation = FloatingWindowPresentation(state: shortState)
        let longPresentation = FloatingWindowPresentation(state: longState)

        XCTAssertGreaterThan(shortPresentation.preferredSize.height, FloatingWindowPresentation.minimumPanelHeight)
        XCTAssertLessThan(shortPresentation.preferredSize.height, 220)
        XCTAssertGreaterThan(longPresentation.preferredSize.height, shortPresentation.preferredSize.height)
        XCTAssertLessThanOrEqual(longPresentation.preferredSize.height, FloatingWindowPresentation.maximumPanelHeight)
    }

    func testVeryLongTranscriptCapsPanelHeight() {
        let state = AppState()
        state.status = .listening
        state.rawTranscript = Array(repeating: "很长的内容会继续增长，但是浮窗不能超过屏幕里合理的高度。", count: 80).joined()

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.preferredSize.height, FloatingWindowPresentation.maximumPanelHeight)
    }

    func testAudioQualityMetersExposeOnlyInputAndNoiseAtBottomTrailing() {
        let state = AppState()
        state.status = .listening
        state.audioQualitySnapshot = AudioQualitySnapshot(
            issue: .tooQuiet,
            rmsDBFS: -50,
            peakDBFS: -30,
            crestDB: 20
        )

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.audioQualityMeterPlacement, .bottomTrailing)
        XCTAssertEqual(presentation.audioQualityMeters.map(\.kind), [.inputVolume, .backgroundNoise])
        XCTAssertEqual(presentation.audioQualityMeters.map(\.status), [.low, .good])
        XCTAssertEqual(presentation.audioQualityMeters.map(\.title), ["输入音量", "环境噪音"])
    }

    func testAudioQualityMeterStatusUsesRangeInsteadOfBinaryProblemState() {
        let loudState = AppState()
        loudState.status = .listening
        loudState.audioQualitySnapshot = AudioQualitySnapshot(
            issue: .clipping,
            rmsDBFS: -8,
            peakDBFS: -0.1,
            crestDB: 8
        )

        let noisyState = AppState()
        noisyState.status = .listening
        noisyState.audioQualitySnapshot = AudioQualitySnapshot(
            issue: .backgroundNoise,
            rmsDBFS: -32,
            peakDBFS: -28,
            crestDB: 4
        )

        let loudPresentation = FloatingWindowPresentation(state: loudState)
        let noisyPresentation = FloatingWindowPresentation(state: noisyState)

        XCTAssertEqual(loudPresentation.audioQualityMeters.map(\.status), [.high, .good])
        XCTAssertEqual(noisyPresentation.audioQualityMeters.map(\.status), [.good, .high])
    }

    func testSlightlyLowInputVolumeOnlyShowsGentleWarning() {
        let state = AppState()
        state.status = .listening
        state.audioQualitySnapshot = AudioQualitySnapshot(
            issue: .tooQuiet,
            rmsDBFS: -44,
            peakDBFS: -24,
            crestDB: 20
        )

        let presentation = FloatingWindowPresentation(state: state)
        let inputMeter = presentation.audioQualityMeters.first { $0.kind == .inputVolume }

        XCTAssertEqual(inputMeter?.status, .low)
        XCTAssertLessThanOrEqual(inputMeter?.severity ?? 1, 0.25)
    }

    func testAudioQualityMetersShowNeutralPlaceholdersBeforeAudioArrives() {
        let state = AppState()
        state.status = .listening

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(presentation.audioQualityMeterPlacement, .bottomTrailing)
        XCTAssertEqual(presentation.audioQualityMeters.map(\.kind), [.inputVolume, .backgroundNoise])
        XCTAssertEqual(presentation.audioQualityMeters.map(\.status), [.good, .good])
        XCTAssertEqual(presentation.audioQualityMeters.map(\.severity), [0, 0])
    }

    func testCompactPanelTightensBottomWhitespace() {
        XCTAssertLessThanOrEqual(FloatingWindowPresentation.minimumCardHeight, 205)
        XCTAssertLessThan(FloatingWindowPresentation.minimumCardHeight, 220)
        XCTAssertGreaterThanOrEqual(
            FloatingWindowPresentation.minimumTextViewportHeight,
            CGFloat(FloatingWindowPresentation.minimumTextLineCount) * FloatingWindowPresentation.textLineHeight
        )
    }

    func testLongTranscriptCanGrowBeyondPreviousHeightCap() {
        let state = AppState()
        state.status = .listening
        state.rawTranscript = Array(
            repeating: "这是一段比较长的输入内容，用来确认输入文字变多时浮窗会继续变高，不会过早把文字挤在很小的区域里。",
            count: 28
        ).joined()

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertGreaterThan(FloatingWindowPresentation.maximumCardHeight, 420)
        XCTAssertGreaterThan(presentation.visibleCardHeight, 420)
    }

    func testCompactPanelStillLeavesThreeReadableTextLines() {
        let state = AppState()
        state.status = .listening
        state.rawTranscript = "短输入。"
        state.audioQualitySnapshot = AudioQualitySnapshot(
            issue: nil,
            rmsDBFS: -26,
            peakDBFS: -10,
            crestDB: 16
        )

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertGreaterThanOrEqual(
            presentation.textViewportHeight,
            FloatingWindowPresentation.minimumTextViewportHeight
        )
    }

    func testLongTranscriptIncreasesReadableTextViewport() {
        let shortState = AppState()
        shortState.status = .listening
        shortState.rawTranscript = "短输入。"

        let longState = AppState()
        longState.status = .listening
        longState.rawTranscript = Array(
            repeating: "这是一段更长的测试文本，用来确认正文区域本身会随着文字增多而变高，而不是只让外框变高。",
            count: 16
        ).joined()

        let shortPresentation = FloatingWindowPresentation(state: shortState)
        let longPresentation = FloatingWindowPresentation(state: longState)

        XCTAssertGreaterThan(longPresentation.textViewportHeight, shortPresentation.textViewportHeight)
        XCTAssertGreaterThan(longPresentation.textViewportHeight, FloatingWindowPresentation.minimumTextViewportHeight)
    }

    func testLongTranscriptViewportLeavesComfortPaddingBelowMeasuredText() {
        let transcript = [
            "这回我再测试一下，看看它这玩意儿怎么样啊？试一下试一下。",
            "这个输入音量颜色不太行，环境噪音的颜色也不应该影响文字。",
            "我希望这一整段都能显示出来，不要最后一行只露出来一半。",
            "底部可以留一点点空余，但是不要太大。"
        ].joined()
        let state = AppState()
        state.status = .listening
        state.rawTranscript = transcript
        state.audioQualitySnapshot = AudioQualitySnapshot(
            issue: nil,
            rmsDBFS: -24,
            peakDBFS: -8,
            crestDB: 16
        )

        let presentation = FloatingWindowPresentation(state: state)
        let measuredTextHeight = measuredHeight(
            transcript,
            fontSize: 16,
            width: FloatingWindowPresentation.textContentWidth
        )

        XCTAssertLessThan(presentation.visibleCardHeight, FloatingWindowPresentation.maximumCardHeight)
        XCTAssertGreaterThanOrEqual(
            presentation.textViewportHeight,
            measuredTextHeight + FloatingWindowPresentation.textViewportComfortPadding
        )
    }

    func testAudioQualityMeterTitlesStayNeutralWhenDotColorChanges() {
        let state = AppState()
        state.status = .listening
        state.audioQualitySnapshot = AudioQualitySnapshot(
            issue: .backgroundNoise,
            rmsDBFS: -30,
            peakDBFS: -20,
            crestDB: 4
        )

        let presentation = FloatingWindowPresentation(state: state)

        XCTAssertEqual(
            presentation.audioQualityMeters.map(\.titleColorRole),
            [.secondary, .secondary]
        )
    }

    private func measuredHeight(_ text: String, fontSize: CGFloat, width: CGFloat) -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        let boundingRect = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )

        return ceil(boundingRect.height)
    }
}
