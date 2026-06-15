import AppKit
import SwiftUI

protocol SettingsStore {
    var defaultMode: SpeakMoreMode { get nonmutating set }
    var targetLanguage: String { get nonmutating set }
    var isHistoryEnabled: Bool { get nonmutating set }
    var launchAtLogin: Bool { get nonmutating set }
    var interfaceLanguage: AppLanguage { get nonmutating set }
    var textPolishIntensity: TextPolishIntensity { get nonmutating set }
    var voiceInputShortcut: VoiceInputShortcut { get nonmutating set }
    var speechRecognitionProviderKind: SpeechRecognitionProviderKind { get nonmutating set }
    var speechRecognitionModel: String { get nonmutating set }
    var speechRecognitionEndpoint: String { get nonmutating set }
    var textAIProviderKind: TextAIProviderKind { get nonmutating set }
    var textAIModel: String { get nonmutating set }
    var textAIEndpoint: String { get nonmutating set }
}

protocol APIKeyStore {
    func readAPIKey(account: String) -> String?
    func saveAPIKey(_ apiKey: String, account: String) throws
}

extension SettingsStore {
    var launchAtLogin: Bool {
        get { false }
        nonmutating set {}
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var speechAPIKey: String
    @Published var speechRecognitionProviderKind: SpeechRecognitionProviderKind
    @Published var speechRecognitionModel: String
    @Published var speechRecognitionEndpoint: String
    @Published var textAPIKey: String
    @Published var textAIProviderKind: TextAIProviderKind
    @Published var textAIModel: String
    @Published var textAIEndpoint: String
    @Published var defaultMode: SpeakMoreMode
    @Published var targetLanguage: String
    @Published var isHistoryEnabled: Bool
    @Published var interfaceLanguage: AppLanguage
    @Published var textPolishIntensity: TextPolishIntensity
    @Published var voiceInputShortcut: VoiceInputShortcut
    @Published private(set) var needsAPISetup: Bool
    @Published private(set) var saveStatus: String?
    var onSaved: (@MainActor () -> Void)?
    var onOpenTutorial: (@MainActor () -> Void)?

    private var settingsStore: SettingsStore
    private let apiKeyStore: APIKeyStore
    private var loadedDefaultMode: SpeakMoreMode
    private var loadedTargetLanguage: String
    private var loadedIsHistoryEnabled: Bool
    private var loadedInterfaceLanguage: AppLanguage
    private var loadedTextPolishIntensity: TextPolishIntensity
    private var loadedVoiceInputShortcut: VoiceInputShortcut
    private var loadedSpeechRecognitionProviderKind: SpeechRecognitionProviderKind
    private var loadedSpeechRecognitionModel: String
    private var loadedSpeechRecognitionEndpoint: String
    private var loadedTextAIProviderKind: TextAIProviderKind
    private var loadedTextAIModel: String
    private var loadedTextAIEndpoint: String

    init(
        settingsStore: SettingsStore = AppSettings(),
        apiKeyStore: APIKeyStore = LocalAPIKeyStore(),
        onSaved: (@MainActor () -> Void)? = nil,
        onOpenTutorial: (@MainActor () -> Void)? = nil
    ) {
        self.settingsStore = settingsStore
        self.apiKeyStore = apiKeyStore
        self.onSaved = onSaved
        self.onOpenTutorial = onOpenTutorial
        self.speechAPIKey = ""
        self.speechRecognitionProviderKind = .aliyunBailianRealtime
        self.speechRecognitionModel = SpeechRecognitionProviderKind.aliyunBailianRealtime.defaultModel
        self.speechRecognitionEndpoint = SpeechRecognitionProviderKind.aliyunBailianRealtime.defaultEndpoint
        self.textAPIKey = ""
        self.textAIProviderKind = .aliyunBailian
        self.textAIModel = TextAIProviderKind.aliyunBailian.defaultModel
        self.textAIEndpoint = TextAIProviderKind.aliyunBailian.defaultEndpoint
        self.defaultMode = .auto
        self.targetLanguage = "English"
        self.isHistoryEnabled = false
        self.interfaceLanguage = .system
        self.textPolishIntensity = .medium
        self.voiceInputShortcut = .default
        self.needsAPISetup = false
        self.loadedDefaultMode = .auto
        self.loadedTargetLanguage = "English"
        self.loadedIsHistoryEnabled = false
        self.loadedInterfaceLanguage = .system
        self.loadedTextPolishIntensity = .medium
        self.loadedVoiceInputShortcut = .default
        self.loadedSpeechRecognitionProviderKind = .aliyunBailianRealtime
        self.loadedSpeechRecognitionModel = SpeechRecognitionProviderKind.aliyunBailianRealtime.defaultModel
        self.loadedSpeechRecognitionEndpoint = SpeechRecognitionProviderKind.aliyunBailianRealtime.defaultEndpoint
        self.loadedTextAIProviderKind = .aliyunBailian
        self.loadedTextAIModel = TextAIProviderKind.aliyunBailian.defaultModel
        self.loadedTextAIEndpoint = TextAIProviderKind.aliyunBailian.defaultEndpoint
        refreshFromStore()
    }

    func refreshFromStore() {
        defaultMode = settingsStore.defaultMode
        targetLanguage = settingsStore.targetLanguage
        isHistoryEnabled = settingsStore.isHistoryEnabled
        interfaceLanguage = settingsStore.interfaceLanguage
        textPolishIntensity = settingsStore.textPolishIntensity
        voiceInputShortcut = settingsStore.voiceInputShortcut
        speechRecognitionProviderKind = settingsStore.speechRecognitionProviderKind
        speechRecognitionModel = settingsStore.speechRecognitionModel
        speechRecognitionEndpoint = settingsStore.speechRecognitionEndpoint
        textAIProviderKind = settingsStore.textAIProviderKind
        textAIModel = settingsStore.textAIModel
        textAIEndpoint = settingsStore.textAIEndpoint
        speechAPIKey = firstAPIKey(for: speechRecognitionProviderKind.apiKeyAccounts)
        textAPIKey = firstAPIKey(for: textAIProviderKind.apiKeyAccounts)
        needsAPISetup = speechAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || textAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        loadedDefaultMode = defaultMode
        loadedTargetLanguage = targetLanguage
        loadedIsHistoryEnabled = isHistoryEnabled
        loadedInterfaceLanguage = interfaceLanguage
        loadedTextPolishIntensity = textPolishIntensity
        loadedVoiceInputShortcut = voiceInputShortcut
        loadedSpeechRecognitionProviderKind = speechRecognitionProviderKind
        loadedSpeechRecognitionModel = speechRecognitionModel
        loadedSpeechRecognitionEndpoint = speechRecognitionEndpoint
        loadedTextAIProviderKind = textAIProviderKind
        loadedTextAIModel = textAIModel
        loadedTextAIEndpoint = textAIEndpoint
    }

    func save() throws {
        let strings = AppInterfaceStrings(language: interfaceLanguage)

        if defaultMode != loadedDefaultMode {
            settingsStore.defaultMode = defaultMode
        }

        if targetLanguage != loadedTargetLanguage {
            settingsStore.targetLanguage = targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if isHistoryEnabled != loadedIsHistoryEnabled {
            settingsStore.isHistoryEnabled = isHistoryEnabled
        }

        if interfaceLanguage != loadedInterfaceLanguage {
            settingsStore.interfaceLanguage = interfaceLanguage
        }

        if textPolishIntensity != loadedTextPolishIntensity {
            settingsStore.textPolishIntensity = textPolishIntensity
        }

        if voiceInputShortcut != loadedVoiceInputShortcut {
            settingsStore.voiceInputShortcut = voiceInputShortcut
        }

        if speechRecognitionProviderKind != loadedSpeechRecognitionProviderKind {
            settingsStore.speechRecognitionProviderKind = speechRecognitionProviderKind
        }

        if speechRecognitionModel != loadedSpeechRecognitionModel {
            settingsStore.speechRecognitionModel = speechRecognitionModel.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if speechRecognitionEndpoint != loadedSpeechRecognitionEndpoint {
            settingsStore.speechRecognitionEndpoint = speechRecognitionEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if textAIProviderKind != loadedTextAIProviderKind {
            settingsStore.textAIProviderKind = textAIProviderKind
        }

        if textAIModel != loadedTextAIModel {
            settingsStore.textAIModel = textAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if textAIEndpoint != loadedTextAIEndpoint {
            settingsStore.textAIEndpoint = textAIEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let trimmedSpeechAPIKey = speechAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSpeechAPIKey.isEmpty {
            do {
                try apiKeyStore.saveAPIKey(trimmedSpeechAPIKey, account: speechRecognitionProviderKind.apiKeyAccount)
            } catch {
                saveStatus = strings.unableToSaveSpeechAPIKey
                throw error
            }
        }

        let trimmedTextAPIKey = textAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTextAPIKey.isEmpty {
            do {
                try apiKeyStore.saveAPIKey(trimmedTextAPIKey, account: textAIProviderKind.apiKeyAccount)
            } catch {
                saveStatus = strings.unableToSaveTextAPIKey
                throw error
            }
        }

        refreshFromStore()
        saveStatus = AppInterfaceStrings(language: interfaceLanguage).saved
        onSaved?()
    }

    func openTutorial() {
        onOpenTutorial?()
    }

    func selectSpeechRecognitionProvider(_ provider: SpeechRecognitionProviderKind) {
        speechRecognitionProviderKind = provider
        speechRecognitionModel = provider.defaultModel
        speechRecognitionEndpoint = provider.defaultEndpoint
        speechAPIKey = firstAPIKey(for: provider.apiKeyAccounts)
    }

    func selectTextAIProvider(_ provider: TextAIProviderKind) {
        textAIProviderKind = provider
        textAIModel = provider.defaultModel
        textAIEndpoint = provider.defaultEndpoint
        textAPIKey = firstAPIKey(for: provider.apiKeyAccounts)
    }

    private func firstAPIKey(for accounts: [String]) -> String {
        for account in accounts {
            let key = apiKeyStore.readAPIKey(account: account)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !key.isEmpty {
                return key
            }
        }
        return ""
    }
}

struct SettingsView: View {
    @StateObject private var model: SettingsViewModel
    @State private var showsSpeechAdvancedSettings = false
    @State private var showsTextAdvancedSettings = false

    init(model: SettingsViewModel = SettingsViewModel()) {
        _model = StateObject(wrappedValue: model)
    }

    private var strings: AppInterfaceStrings {
        AppInterfaceStrings(language: model.interfaceLanguage)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if model.needsAPISetup {
                        setupBanner
                    }

                    settingsSection(strings.defaultBehavior, subtitle: strings.defaultBehaviorSubtitle) {
                        modeList

                        settingsRow(strings.translationTarget) {
                            TextField(strings.translationTarget, text: $model.targetLanguage)
                        }

                        settingsRow(strings.polishIntensity) {
                            Picker("", selection: $model.textPolishIntensity) {
                                ForEach(TextPolishIntensity.allCases, id: \.self) { intensity in
                                    Text("\(strings.polishIntensityTitle(intensity)) - \(strings.polishIntensitySubtitle(intensity))").tag(intensity)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    settingsSection(strings.shortcutSettings, subtitle: strings.shortcutSettingsSubtitle) {
                        settingsRow(strings.triggerStyle) {
                            Picker("", selection: Binding(
                                get: { model.voiceInputShortcut.trigger },
                                set: { model.voiceInputShortcut.trigger = $0 }
                            )) {
                                ForEach(VoiceInputShortcutTrigger.allCases, id: \.self) { trigger in
                                    Text(strings.voiceInputShortcutTriggerTitle(trigger)).tag(trigger)
                                }
                            }
                            .labelsHidden()
                        }

                        settingsRow(strings.voiceInputShortcut) {
                            ShortcutRecorderButton(strings: strings, shortcut: $model.voiceInputShortcut)
                        }

                        Text(strings.shortcutRecorderHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    settingsSection(strings.speechRecognition, subtitle: strings.speechRecognitionSubtitle) {
                        settingsRow(strings.speechService) {
                            Picker("", selection: $model.speechRecognitionProviderKind) {
                                ForEach(SpeechRecognitionProviderKind.allCases, id: \.self) { provider in
                                    Text(strings.speechRecognitionProviderTitle(provider)).tag(provider)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: model.speechRecognitionProviderKind) { _, provider in
                                model.selectSpeechRecognitionProvider(provider)
                            }
                        }
                        settingsRow("API Key") {
                            SecureField(strings.speechAPIKeyPlaceholder, text: $model.speechAPIKey)
                        }

                        advancedDisclosure(isExpanded: $showsSpeechAdvancedSettings) {
                            settingsRow(strings.modelLabel) {
                                TextField(strings.speechModelPlaceholder, text: $model.speechRecognitionModel)
                            }
                            settingsRow(strings.endpoint) {
                                TextField(strings.speechEndpointPlaceholder, text: $model.speechRecognitionEndpoint)
                            }
                        }
                    }

                    settingsSection(strings.textAI, subtitle: strings.textAISubtitle) {
                        settingsRow(strings.aiService) {
                            Picker("", selection: $model.textAIProviderKind) {
                                ForEach(TextAIProviderKind.allCases, id: \.self) { provider in
                                    Text(strings.textAIProviderTitle(provider)).tag(provider)
                                }
                            }
                            .labelsHidden()
                            .onChange(of: model.textAIProviderKind) { _, provider in
                                model.selectTextAIProvider(provider)
                            }
                        }
                        settingsRow("API Key") {
                            SecureField(strings.textAPIKeyPlaceholder, text: $model.textAPIKey)
                        }

                        advancedDisclosure(isExpanded: $showsTextAdvancedSettings) {
                            settingsRow(strings.modelLabel) {
                                TextField(strings.textModelPlaceholder, text: $model.textAIModel)
                            }
                            settingsRow(strings.endpoint) {
                                TextField(strings.textEndpointPlaceholder, text: $model.textAIEndpoint)
                            }
                        }
                    }

                    settingsSection(strings.appearanceAndPermissions, subtitle: strings.appearanceAndPermissionsSubtitle) {
                        settingsRow(strings.interfaceLanguage) {
                            Picker("", selection: $model.interfaceLanguage) {
                                ForEach(AppLanguage.allCases, id: \.self) { language in
                                    Text(strings.languageTitle(language)).tag(language)
                                }
                            }
                            .labelsHidden()
                        }

                        Toggle(strings.saveHistory, isOn: $model.isHistoryEnabled)

                        Toggle(isOn: .constant(false)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(strings.launchAtLogin)
                                Text(strings.comingAfterPackaging)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(true)

                        Divider()
                        PermissionView(language: model.interfaceLanguage)
                    }

                    settingsSection(strings.tutorial, subtitle: strings.tutorialSubtitle) {
                        Button {
                            model.openTutorial()
                        } label: {
                            Label(strings.reopenTutorial, systemImage: "book")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding(24)
            }

            Divider()
            saveBar
        }
        .frame(width: 760, height: 660)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings.settingsWindowTitle)
                .font(.system(size: 24, weight: .semibold))
            Text(strings.settingsSubtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var modeList: some View {
        VStack(spacing: 8) {
            ForEach(SpeakMoreMode.allCases, id: \.self) { mode in
                Button {
                    model.defaultMode = mode
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: model.defaultMode == mode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(model.defaultMode == mode ? .blue : .secondary)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(strings.modeTitle(mode))
                                .font(.system(size: 14, weight: .semibold))
                            Text(strings.modeSubtitle(mode))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var saveBar: some View {
        HStack {
            if let saveStatus = model.saveStatus {
                Text(saveStatus)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(strings.save) {
                do {
                    try model.save()
                } catch {
                    NSLog("\(AppBrand.englishName) settings save failed: \(error.localizedDescription)")
                }
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func settingsSection<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func settingsRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 86, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func advancedDisclosure<Content: View>(
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(.top, 8)
        } label: {
            Text(strings.advancedSettings)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setupBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.apiSetup)
                .font(.headline)
            Text(strings.apiSetupDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Link(strings.openAliyun, destination: URL(string: "https://bailian.console.aliyun.com/")!)
                Link(strings.openSiliconFlow, destination: URL(string: "https://cloud.siliconflow.cn/me/account/ak")!)
                Spacer()
            }
            .font(.callout)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ShortcutRecorderButton: View {
    let strings: AppInterfaceStrings
    @Binding var shortcut: VoiceInputShortcut
    @State private var isRecording = false
    @State private var validationMessage: String?
    @State private var eventMonitor: Any?
    @State private var pendingModifierRecording: DispatchWorkItem?

    var body: some View {
        HStack(spacing: 10) {
            Button {
                isRecording ? stopRecording() : startRecording()
            } label: {
                Label(
                    isRecording ? strings.recordingShortcut : shortcut.displayTitle,
                    systemImage: "keyboard"
                )
            }
            .controlSize(.large)

            Button(strings.recordShortcut) {
                startRecording()
            }
            .disabled(isRecording)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        validationMessage = nil
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { event in
            handle(event)
        }
    }

    private func stopRecording() {
        pendingModifierRecording?.cancel()
        pendingModifierRecording = nil
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
        isRecording = false
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .flagsChanged:
            let modifiers = ShortcutModifiers(eventModifierFlags: event.modifierFlags)
            guard !modifiers.isEmpty else {
                return event
            }
            scheduleModifierOnlyRecording(modifiers)
            return event
        case .keyDown:
            pendingModifierRecording?.cancel()
            let modifiers = ShortcutModifiers(eventModifierFlags: event.modifierFlags)
            guard !modifiers.isEmpty else {
                validationMessage = strings.invalidShortcut
                return nil
            }
            shortcut.binding = VoiceInputShortcutBinding(
                modifiers: modifiers,
                keyCode: event.keyCode,
                charactersIgnoringModifiers: event.charactersIgnoringModifiers
            )
            stopRecording()
            return nil
        default:
            return event
        }
    }

    private func scheduleModifierOnlyRecording(_ modifiers: ShortcutModifiers) {
        pendingModifierRecording?.cancel()
        let workItem = DispatchWorkItem {
            shortcut.binding = VoiceInputShortcutBinding(
                modifiers: modifiers,
                keyCode: nil,
                charactersIgnoringModifiers: nil
            )
            stopRecording()
        }
        pendingModifierRecording = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: workItem)
    }
}
