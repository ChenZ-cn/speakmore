import XCTest
@testable import SpeakMore

@MainActor
final class MenuBarControllerTests: XCTestCase {
    func testControlStartWithSelectedTextAutomaticallyUsesAskSelectedTextMode() async throws {
        let defaults = UserDefaults(suiteName: "MenuBarControllerTests.autoAskSelectedText")!
        defaults.removePersistentDomain(forName: "MenuBarControllerTests.autoAskSelectedText")
        let settings = AppSettings(defaults: defaults)
        settings.defaultMode = .dictate
        let state = AppState()
        let realtimeProvider = MenuManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: MenuCapturingPasteSink(),
            networkAvailabilityChecker: MenuFixedNetworkAvailabilityChecker(isNetworkAvailable: true)
        )
        let floatingPanelController = MenuSpyFloatingPanelController(state: state)
        let menuBarController = MenuBarController(
            controller: controller,
            floatingPanelController: floatingPanelController,
            state: state,
            settings: settings,
            openSettings: {},
            selectedTextReader: FixedSelectedTextReader(selectedText: "被选中的文字")
        )

        menuBarController.startDictation()
        await waitForSessionCount(1, realtimeProvider: realtimeProvider)
        await waitForMode(.askSelectedText, state: state)

        XCTAssertEqual(state.selectedText, "被选中的文字")
    }

    func testStartShowsFloatingPanelAfterListeningStateIsReady() async throws {
        let defaults = UserDefaults(suiteName: "MenuBarControllerTests.showAfterListening")!
        defaults.removePersistentDomain(forName: "MenuBarControllerTests.showAfterListening")
        let settings = AppSettings(defaults: defaults)
        settings.defaultMode = .dictate
        let state = AppState()
        let realtimeProvider = MenuManualRealtimeTranscriptionProvider()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: realtimeProvider,
            textProvider: FakeTextTransformProvider(),
            pasteSink: MenuCapturingPasteSink(),
            networkAvailabilityChecker: MenuFixedNetworkAvailabilityChecker(isNetworkAvailable: true)
        )
        let floatingPanelController = MenuSpyFloatingPanelController(state: state)
        let menuBarController = MenuBarController(
            controller: controller,
            floatingPanelController: floatingPanelController,
            state: state,
            settings: settings,
            openSettings: {},
            selectedTextReader: FixedSelectedTextReader(selectedText: nil)
        )

        menuBarController.startDictation()
        await waitForPanelShow(floatingPanelController)

        XCTAssertEqual(floatingPanelController.statusesAtShow, [.listening])
    }

    func testMenuLanguageChangeUpdatesStateAndPersistedSetting() {
        let defaults = UserDefaults(suiteName: "MenuBarControllerTests.languageChange")!
        defaults.removePersistentDomain(forName: "MenuBarControllerTests.languageChange")
        let settings = AppSettings(defaults: defaults)
        let state = AppState()
        let controller = SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: MenuManualRealtimeTranscriptionProvider(),
            textProvider: FakeTextTransformProvider(),
            pasteSink: MenuCapturingPasteSink(),
            networkAvailabilityChecker: MenuFixedNetworkAvailabilityChecker(isNetworkAvailable: true)
        )
        let menuBarController = MenuBarController(
            controller: controller,
            floatingPanelController: MenuSpyFloatingPanelController(state: state),
            state: state,
            settings: settings,
            openSettings: {},
            selectedTextReader: FixedSelectedTextReader(selectedText: nil)
        )

        menuBarController.changeInterfaceLanguageFromMenu(.english)

        XCTAssertEqual(state.interfaceLanguage, .english)
        XCTAssertEqual(settings.interfaceLanguage, .english)
        XCTAssertEqual(AppSettings(defaults: defaults).interfaceLanguage, .english)
    }

    private func waitForSessionCount(
        _ expectedCount: Int,
        realtimeProvider: MenuManualRealtimeTranscriptionProvider,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where realtimeProvider.sessionCount < expectedCount {
            await Task.yield()
        }

        XCTAssertGreaterThanOrEqual(realtimeProvider.sessionCount, expectedCount, file: file, line: line)
    }

    private func waitForMode(
        _ expectedMode: SpeakMoreMode,
        state: AppState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where state.mode != expectedMode {
            await Task.yield()
        }

        XCTAssertEqual(state.mode, expectedMode, file: file, line: line)
    }

    private func waitForPanelShow(
        _ floatingPanelController: MenuSpyFloatingPanelController,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 where floatingPanelController.statusesAtShow.isEmpty {
            await Task.yield()
        }

        XCTAssertFalse(floatingPanelController.statusesAtShow.isEmpty, file: file, line: line)
    }
}

@MainActor
private final class MenuSpyFloatingPanelController: FloatingPanelControlling {
    private let state: AppState
    private(set) var statusesAtShow: [SpeakMoreSessionStatus] = []

    init(state: AppState) {
        self.state = state
    }

    func show() {
        statusesAtShow.append(state.status)
    }

    func hide() {}
}

@MainActor
private final class FixedSelectedTextReader: SelectedTextReading {
    let selectedText: String?

    init(selectedText: String?) {
        self.selectedText = selectedText
    }

    func readSelectedText() async -> String? {
        selectedText
    }
}

@MainActor
private struct MenuFixedNetworkAvailabilityChecker: NetworkAvailabilityChecking {
    let isNetworkAvailable: Bool
}

@MainActor
private final class MenuCapturingPasteSink: PasteTextSink {
    func paste(text: String) throws {}
    func revertLastPastedText() throws -> Bool { false }
    func revertLastPastedSentence() throws -> Bool { false }
}

private final class MenuManualRealtimeTranscriptionProvider: RealtimeTranscriptionProvider {
    private var continuations: [AsyncThrowingStream<TranscriptDelta, Error>.Continuation] = []

    var sessionCount: Int {
        continuations.count
    }

    func startTranscription() -> AsyncThrowingStream<TranscriptDelta, Error> {
        AsyncThrowingStream { continuation in
            continuations.append(continuation)
        }
    }

    func stop() {}

    func abort() {}
}
