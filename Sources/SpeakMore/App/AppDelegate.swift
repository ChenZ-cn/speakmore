import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var state: AppState?
    private var settings: AppSettings?
    private var controller: SpeakMoreController?
    private var pasteController: PasteController?
    private var hotKeyController: HotKeyController?
    private var floatingPanelController: FloatingPanelController?
    private var menuBarController: MenuBarController?
    private var settingsWindowController: NSWindowController?
    private var welcomeOnboardingWindowController: WelcomeOnboardingWindowController?
    private let networkAvailabilityChecker = NetworkAvailabilityChecker()
    private var didPromptForPermissions = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let state = AppState()
        let settings = AppSettings()
        let shouldShowWelcome = shouldShowWelcomeOnboarding(settings: settings)
        state.interfaceLanguage = settings.interfaceLanguage
        let pasteController = PasteController()
        let controller = makeController(state: state, settings: settings, pasteController: pasteController)
        let floatingPanelController = FloatingPanelController(state: state) {
            controller.cancelSession()
        } onOpenSettings: { [weak self] in
            self?.showSettingsWindow()
        }
        let menuBarController = MenuBarController(
            controller: controller,
            floatingPanelController: floatingPanelController,
            state: state,
            settings: settings,
            openSettings: { [weak self] in
                self?.showSettingsWindow()
            }
        )

        self.state = state
        self.settings = settings
        self.controller = controller
        self.pasteController = pasteController
        self.floatingPanelController = floatingPanelController
        self.menuBarController = menuBarController
        rebuildHotKeyController()

        if shouldShowWelcome {
            showWelcomeOnboardingWindow()
        } else {
            promptForPermissionsIfNeeded()
        }

        if !shouldShowWelcome, shouldShowSetup(settings: settings) {
            showSettingsWindow()
        }
    }

    private func showWelcomeOnboardingWindow() {
        if let welcomeOnboardingWindowController {
            welcomeOnboardingWindowController.show()
            return
        }

        let windowController = WelcomeOnboardingWindowController { [weak self] in
            self?.finishWelcomeOnboarding()
        }
        welcomeOnboardingWindowController = windowController
        windowController.show()
    }

    private func finishWelcomeOnboarding() {
        welcomeOnboardingWindowController = nil
        settings?.hasSeenWelcomeOnboarding = true
        promptForPermissionsIfNeeded()

        if let settings, shouldShowSetup(settings: settings) {
            showSettingsWindow()
        }
    }

    private func promptForPermissionsIfNeeded() {
        guard !didPromptForPermissions else { return }
        didPromptForPermissions = true
        PermissionPrompter.promptForAccessibilityIfNeeded()
        PermissionPrompter.promptForMicrophoneIfNeeded()
    }

    private func showSettingsWindow() {
        if let settingsWindowController {
            settingsWindowController.contentViewController = makeSettingsHostingController()
            settingsWindowController.showWindow(nil)
            settingsWindowController.window?.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let window = NSWindow(contentViewController: makeSettingsHostingController())
        window.title = AppInterfaceStrings(language: settings?.interfaceLanguage ?? .system).settingsWindowTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        let windowController = NSWindowController(window: window)
        self.settingsWindowController = windowController
        windowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func makeSettingsHostingController() -> NSHostingController<SettingsView> {
        let model = SettingsViewModel(
            settingsStore: settings ?? AppSettings(),
            apiKeyStore: LocalAPIKeyStore(),
            onSaved: { [weak self] in
                if let settings = self?.settings {
                    self?.state?.interfaceLanguage = settings.interfaceLanguage
                    self?.settingsWindowController?.window?.title = AppInterfaceStrings(language: settings.interfaceLanguage).settingsWindowTitle
                }
                self?.rebuildController()
                self?.rebuildHotKeyController()
                self?.settingsWindowController?.window?.close()
            },
            onOpenTutorial: { [weak self] in
                self?.showWelcomeOnboardingWindow()
            }
        )
        return NSHostingController(rootView: SettingsView(model: model))
    }

    private func rebuildController() {
        guard let state, let settings, let pasteController else { return }
        let controller = makeController(state: state, settings: settings, pasteController: pasteController)
        self.controller = controller
        menuBarController?.updateController(controller)
    }

    private func rebuildHotKeyController() {
        guard let settings, let menuBarController else { return }

        hotKeyController = nil
        let hotKeyController = HotKeyController(shortcut: settings.voiceInputShortcut) {
            Task { @MainActor in
                menuBarController.startDictation()
            }
        } onReleased: {
            Task { @MainActor in
                menuBarController.stopDictation()
            }
        } onModeShortcut: { mode in
            Task { @MainActor in
                menuBarController.switchModeDuringDictation(mode)
            }
        }

        do {
            try hotKeyController.registerDefaultHotKey()
            self.hotKeyController = hotKeyController
        } catch {
            NSLog("\(AppBrand.englishName) hot key registration failed: \(error.localizedDescription)")
        }
    }

    private func makeController(
        state: AppState,
        settings: AppSettings,
        pasteController: PasteController
    ) -> SpeakMoreController {
        let providers = makeProviders(settings: settings, state: state)
        return SpeakMoreController(
            state: state,
            settings: settings,
            realtimeProvider: providers.realtime,
            textProvider: providers.text,
            pasteSink: pasteController,
            networkAvailabilityChecker: networkAvailabilityChecker
        )
    }

    private func makeProviders(settings: AppSettings, state: AppState) -> (realtime: RealtimeTranscriptionProvider, text: TextTransformProvider) {
        let keyStore = LocalAPIKeyStore()
        let speechProviderKind = settings.speechRecognitionProviderKind
        let speechKeys = APIKeyResolver(
            primaryStore: keyStore,
            fallbackStore: KeychainStore(),
            accounts: speechProviderKind.apiKeyAccounts
        ).apiKeys()
        let textProviderKind = settings.textAIProviderKind
        let textKeys = APIKeyResolver(
            primaryStore: keyStore,
            fallbackStore: KeychainStore(),
            accounts: textProviderKind.apiKeyAccounts
        ).apiKeys()

        let realtimeProvider = makeRealtimeProvider(
            keys: speechKeys,
            providerKind: speechProviderKind,
            model: settings.speechRecognitionModel.nonEmpty ?? speechProviderKind.defaultModel,
            endpoint: URL(string: settings.speechRecognitionEndpoint.nonEmpty ?? speechProviderKind.defaultEndpoint)
                ?? URL(string: speechProviderKind.defaultEndpoint)!,
            state: state
        )

        let textProvider = makeTextProvider(
            keys: textKeys,
            providerKind: textProviderKind,
            model: settings.textAIModel.nonEmpty ?? textProviderKind.defaultModel,
            endpoint: TextAIProviderKind.chatCompletionsEndpoint(from: settings.textAIEndpoint)
                ?? URL(string: textProviderKind.defaultEndpoint)!,
            intensity: settings.textPolishIntensity
        )

        return (realtimeProvider, textProvider)
    }

    private func shouldShowSetup(settings: AppSettings) -> Bool {
        let keyStore = LocalAPIKeyStore()
        let speechKeys = APIKeyResolver(
            primaryStore: keyStore,
            fallbackStore: KeychainStore(),
            accounts: settings.speechRecognitionProviderKind.apiKeyAccounts
        ).apiKeys()
        let textKeys = APIKeyResolver(
            primaryStore: keyStore,
            fallbackStore: KeychainStore(),
            accounts: settings.textAIProviderKind.apiKeyAccounts
        ).apiKeys()

        return speechKeys.isEmpty || textKeys.isEmpty
    }

    private func shouldShowWelcomeOnboarding(settings: AppSettings) -> Bool {
        !settings.hasSeenWelcomeOnboarding
    }

    private func makeRealtimeProvider(
        keys: [String],
        providerKind: SpeechRecognitionProviderKind,
        model: String,
        endpoint: URL,
        state: AppState
    ) -> RealtimeTranscriptionProvider {
        guard let key = keys.first else {
            return FakeRealtimeTranscriptionProvider()
        }

        if keys.count > 1 {
            return FailoverRealtimeTranscriptionProvider(
                providers: keys.map {
                    makeSingleRealtimeProvider(
                        key: $0,
                        providerKind: providerKind,
                        model: model,
                        endpoint: endpoint,
                        state: state
                    )
                }
            )
        }

        return makeSingleRealtimeProvider(
            key: key,
            providerKind: providerKind,
            model: model,
            endpoint: endpoint,
            state: state
        )
    }

    private func makeSingleRealtimeProvider(
        key: String,
        providerKind: SpeechRecognitionProviderKind,
        model: String,
        endpoint: URL,
        state: AppState
    ) -> RealtimeTranscriptionProvider {
        let audioCaptureEngine = makeAudioCaptureEngine(state: state)
        switch providerKind {
        case .aliyunBailianRealtime:
            return AliyunRealtimeTranscriptionProvider(
                apiKey: key,
                model: model,
                endpoint: endpoint,
                audioCaptureEngine: audioCaptureEngine
            )
        case .openAIRealtime, .customOpenAIRealtime:
            return OpenAIRealtimeTranscriptionProvider(
                apiKey: key,
                model: model,
                endpoint: endpoint,
                audioCaptureEngine: audioCaptureEngine
            )
        }
    }

    private func makeAudioCaptureEngine(state: AppState) -> AudioCaptureEngine {
        AudioCaptureEngine(
            audioQualityMonitor: AudioQualityMonitor { [weak state] snapshot in
                guard let state else { return }
                switch state.status {
                case .listening, .finalizing:
                    state.audioQualitySnapshot = snapshot
                    state.audioQualityIssue = snapshot.issue
                case .idle, .transforming, .inserting, .noSpeech, .failed:
                    break
                }
            }
        )
    }

    private func makeTextProvider(
        keys: [String],
        providerKind: TextAIProviderKind,
        model: String,
        endpoint: URL,
        intensity: TextPolishIntensity
    ) -> TextTransformProvider {
        guard let key = keys.first else {
            return FakeTextTransformProvider()
        }

        let provider: TextTransformProvider
        let promptBuilder = TextTransformPromptBuilder(intensity: intensity)
        if keys.count > 1 {
            provider = FailoverTextTransformProvider(
                providers: keys.map {
                    OpenAITextTransformProvider(
                        apiKey: $0,
                        model: model,
                        endpoint: endpoint,
                        providerName: providerKind.title,
                        extraRequestBody: providerKind.extraRequestBody,
                        promptBuilder: promptBuilder
                    )
                }
            )
        } else {
            provider = OpenAITextTransformProvider(
                apiKey: key,
                model: model,
                endpoint: endpoint,
                providerName: providerKind.title,
                extraRequestBody: providerKind.extraRequestBody,
                promptBuilder: promptBuilder
            )
        }

        return FastPathTextTransformProvider(remoteProvider: provider)
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
