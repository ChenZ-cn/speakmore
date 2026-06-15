import AppKit
import XCTest
@testable import SpeakMore

@MainActor
final class MenuBarStatusPresentationTests: XCTestCase {
    func testReadyPresentationShowsRunningStatus() {
        let presentation = MenuBarStatusPresentation(status: .idle, mode: .auto)

        XCTAssertEqual(presentation.buttonTitle, "SpeakMore")
        XCTAssertEqual(presentation.menuStatusTitle, "状态：就绪")
        XCTAssertEqual(presentation.toolTip, "SpeakMore 多说有益 正在运行")
    }

    func testEnglishPresentationUsesSelectedInterfaceLanguage() {
        let presentation = MenuBarStatusPresentation(status: .idle, mode: .auto, language: .english)
        let strings = AppInterfaceStrings(language: .english)

        XCTAssertEqual(presentation.buttonTitle, "SpeakMore")
        XCTAssertEqual(presentation.menuStatusTitle, "Status: Ready")
        XCTAssertEqual(strings.startVoiceInput, "Start Voice Input")
        XCTAssertEqual(strings.interfaceLanguage, "Interface Language")
        XCTAssertEqual(strings.quitSpeakMore, "Quit SpeakMore")
    }

    func testStatusBarTitleDoesNotExposeSessionStatus() {
        let statuses: [SpeakMoreSessionStatus] = [
            .idle,
            .listening,
            .finalizing,
            .transforming,
            .inserting,
            .noSpeech,
            .failed("network")
        ]

        for status in statuses {
            XCTAssertEqual(MenuBarStatusPresentation(status: status, mode: .auto).buttonTitle, "SpeakMore")
        }
    }

    func testConfiguredLanguagesHaveLocalizedMenuLabels() {
        let expectedStartLabels: [AppLanguage: String] = [
            .simplifiedChinese: "开始语音输入",
            .english: "Start Voice Input",
            .japanese: "音声入力を開始",
            .korean: "음성 입력 시작",
            .french: "Démarrer la saisie vocale",
            .german: "Spracheingabe starten",
            .spanish: "Iniciar entrada de voz",
            .portuguese: "Iniciar entrada por voz",
            .italian: "Avvia input vocale",
            .russian: "Начать голосовой ввод",
            .arabic: "بدء الإدخال الصوتي",
            .hindi: "वॉइस इनपुट शुरू करें",
            .indonesian: "Mulai input suara",
            .vietnamese: "Bắt đầu nhập bằng giọng nói",
            .thai: "เริ่มป้อนข้อมูลด้วยเสียง"
        ]

        for (language, expectedLabel) in expectedStartLabels {
            XCTAssertEqual(AppInterfaceStrings(language: language).startVoiceInput, expectedLabel)
        }
    }

    func testTransformingPresentationNamesAIWork() {
        let presentation = MenuBarStatusPresentation(status: .transforming, mode: .auto)

        XCTAssertEqual(presentation.buttonTitle, "SpeakMore")
        XCTAssertEqual(presentation.menuStatusTitle, "状态：整理中")
    }

    func testInsertingStateIsNotShownInMenuBar() {
        let presentation = MenuBarStatusPresentation(status: .inserting, mode: .auto)

        XCTAssertEqual(presentation.buttonTitle, "SpeakMore")
        XCTAssertEqual(presentation.menuStatusTitle, "状态：就绪")
    }

    func testNoSpeechPresentationIsNotAnError() {
        let presentation = MenuBarStatusPresentation(status: .noSpeech, mode: .auto)

        XCTAssertEqual(presentation.buttonTitle, "SpeakMore")
        XCTAssertEqual(presentation.menuStatusTitle, "状态：没有检测到输入")
    }

    func testStatusPanelTouchesStatusBarBottomWhenThereIsRoom() {
        let buttonRect = NSRect(x: 320, y: 880, width: 140, height: 24)
        let visibleFrame = NSRect(x: 0, y: 0, width: 1200, height: 904)
        let origin = StatusMenuPanelLayout.origin(
            panelSize: StatusMenuPanelView.panelSize,
            buttonRectOnScreen: buttonRect,
            visibleFrame: visibleFrame
        )

        XCTAssertEqual(StatusMenuPanelView.cardTopInset, 0)
        XCTAssertEqual(origin.y + StatusMenuPanelView.panelSize.height, buttonRect.minY)
    }

    func testStatusPanelContentFitsInsideCard() {
        XCTAssertLessThanOrEqual(StatusMenuPanelView.estimatedContentHeight, StatusMenuPanelView.cardHeight)
    }

    func testStatusPanelKeepsOpenDuringAuxiliaryLanguagePickerInteraction() {
        let panelWindow = NSWindow()
        let otherWindow = NSWindow()

        XCTAssertFalse(
            StatusMenuPanelEventRouting.shouldHidePanel(
                isPanelVisible: true,
                panelWindow: panelWindow,
                anchorWindow: nil,
                eventWindow: otherWindow,
                isAuxiliaryInteractionActive: true
            )
        )
        XCTAssertTrue(
            StatusMenuPanelEventRouting.shouldHidePanel(
                isPanelVisible: true,
                panelWindow: panelWindow,
                anchorWindow: nil,
                eventWindow: otherWindow,
                isAuxiliaryInteractionActive: false
            )
        )
    }
}
