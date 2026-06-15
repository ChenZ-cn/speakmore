import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private var controller: SpeakMoreController
    private let floatingPanelController: FloatingPanelControlling
    private let state: AppState
    private var settings: AppSettings
    private let openSettings: @MainActor () -> Void
    private let selectedTextReader: SelectedTextReading
    private var statusMenuPanelController: StatusMenuPanelController?
    private var statusCancellable: AnyCancellable?

    init(
        controller: SpeakMoreController,
        floatingPanelController: FloatingPanelControlling,
        state: AppState,
        settings: AppSettings,
        openSettings: @escaping @MainActor () -> Void,
        selectedTextReader: SelectedTextReading = SelectedTextReader()
    ) {
        self.controller = controller
        self.floatingPanelController = floatingPanelController
        self.state = state
        self.settings = settings
        self.openSettings = openSettings
        self.selectedTextReader = selectedTextReader
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        let presentation = MenuBarStatusPresentation(status: state.status, mode: state.mode, language: state.interfaceLanguage)
        statusItem.button?.title = presentation.buttonTitle
        statusItem.button?.toolTip = presentation.toolTip
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggleStatusMenu)
        statusMenuPanelController = StatusMenuPanelController(
            state: state,
            startDefault: { [weak self] in self?.startDictation() },
            startMode: { [weak self] mode in self?.startSession(mode: mode, selectedText: nil) },
            openSettings: { [weak self] in self?.openSettingsMenuItem() },
            changeLanguage: { [weak self] language in self?.changeInterfaceLanguageFromMenu(language) },
            quit: { NSApp.terminate(nil) }
        )
        observeStatus()
    }

    func updateController(_ controller: SpeakMoreController) {
        self.controller = controller
    }

    func startDictation() {
        startSession(mode: settings.defaultMode, selectedText: nil, autoDetectSelectedText: true)
    }

    func stopDictation() {
        controller.stopSession()
    }

    func switchModeDuringDictation(_ mode: SpeakMoreMode) {
        guard let generation = controller.switchMode(mode) else {
            return
        }

        if mode == .askSelectedText {
            Task { @MainActor in
                await captureSelectedText(for: generation)
            }
        }
    }

    func changeInterfaceLanguageFromMenu(_ language: AppLanguage) {
        settings.interfaceLanguage = language
        state.interfaceLanguage = language
        updateStatus(state.status)
    }

    private func startSession(
        mode: SpeakMoreMode,
        selectedText: String?,
        autoDetectSelectedText: Bool = false
    ) {
        settings.defaultMode = mode
        Task { @MainActor in
            let generation = await controller.startSession(selectedText: selectedText)
            floatingPanelController.show()
            if mode == .askSelectedText, selectedText == nil {
                await captureSelectedText(for: generation)
            } else if autoDetectSelectedText {
                await captureSelectedText(for: generation, switchToAskSelectedTextIfFound: true)
            }
        }
    }

    private func captureSelectedText(
        for generation: Int,
        switchToAskSelectedTextIfFound: Bool = false
    ) async {
        let selectedText = await selectedTextReader.readSelectedText()
        guard let selectedText else {
            if !switchToAskSelectedTextIfFound {
                controller.updateSelectedText(nil, for: generation)
            }
            return
        }

        if switchToAskSelectedTextIfFound {
            _ = controller.switchMode(.askSelectedText, for: generation)
        }
        controller.updateSelectedText(selectedText, for: generation)
    }

    @objc private func toggleStatusMenu() {
        guard let button = statusItem.button else {
            return
        }
        statusMenuPanelController?.toggle(relativeTo: button)
    }

    @objc private func cancelDictationMenuItem() {
        controller.cancelSession()
        floatingPanelController.hide()
    }

    @objc private func openSettingsMenuItem() {
        openSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func observeStatus() {
        statusCancellable = Publishers.MergeMany(
            state.$status.map { _ in () }.eraseToAnyPublisher(),
            state.$mode.map { _ in () }.eraseToAnyPublisher(),
            state.$interfaceLanguage.map { _ in () }.eraseToAnyPublisher()
        )
        .sink { [weak self] _ in
            guard let self else { return }
            self.updateStatus(self.state.status)
        }
    }

    private func updateStatus(_ status: SpeakMoreSessionStatus) {
        let presentation = MenuBarStatusPresentation(status: status, mode: state.mode, language: state.interfaceLanguage)
        statusItem.button?.title = presentation.buttonTitle
        statusItem.button?.toolTip = presentation.toolTip
    }
}

struct MenuBarStatusPresentation: Equatable {
    let buttonTitle: String
    let menuStatusTitle: String
    let toolTip: String
    let canCancel: Bool

    init(status: SpeakMoreSessionStatus, mode: SpeakMoreMode, language: AppLanguage = .simplifiedChinese) {
        _ = mode
        let presentation = AppInterfaceStrings(language: language).statusPresentation(status: status)
        buttonTitle = AppBrand.englishName
        menuStatusTitle = presentation.menuStatusTitle
        toolTip = presentation.toolTip
        canCancel = presentation.canCancel
    }
}
