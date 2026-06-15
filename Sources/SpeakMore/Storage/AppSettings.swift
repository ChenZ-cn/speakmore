import Foundation

struct AppSettings: SettingsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var defaultMode: SpeakMoreMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.defaultMode),
                  let mode = SpeakMoreMode(rawValue: rawValue) else {
                return .auto
            }
            return mode
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Keys.defaultMode)
        }
    }

    var targetLanguage: String {
        get { defaults.string(forKey: Keys.targetLanguage) ?? "English" }
        nonmutating set { defaults.set(newValue, forKey: Keys.targetLanguage) }
    }

    var isHistoryEnabled: Bool {
        get { defaults.bool(forKey: Keys.isHistoryEnabled) }
        nonmutating set { defaults.set(newValue, forKey: Keys.isHistoryEnabled) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        nonmutating set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }

    var hasSeenWelcomeOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasSeenWelcomeOnboarding) }
        nonmutating set { defaults.set(newValue, forKey: Keys.hasSeenWelcomeOnboarding) }
    }

    var interfaceLanguage: AppLanguage {
        get {
            guard let rawValue = defaults.string(forKey: Keys.interfaceLanguage),
                  let language = AppLanguage(rawValue: rawValue) else {
                return .system
            }
            return language
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Keys.interfaceLanguage)
        }
    }

    var textPolishIntensity: TextPolishIntensity {
        get {
            guard let rawValue = defaults.string(forKey: Keys.textPolishIntensity),
                  let intensity = TextPolishIntensity(rawValue: rawValue) else {
                return .medium
            }
            return intensity
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Keys.textPolishIntensity)
        }
    }

    var voiceInputShortcut: VoiceInputShortcut {
        get {
            guard let rawValue = defaults.string(forKey: Keys.voiceInputShortcut),
                  let shortcut = VoiceInputShortcut(storageValue: rawValue) else {
                return .default
            }
            return shortcut
        }
        nonmutating set {
            if let storageValue = newValue.storageValue {
                defaults.set(storageValue, forKey: Keys.voiceInputShortcut)
            }
        }
    }

    var speechRecognitionProviderKind: SpeechRecognitionProviderKind {
        get {
            guard let rawValue = defaults.string(forKey: Keys.speechRecognitionProviderKind),
                  let provider = SpeechRecognitionProviderKind(rawValue: rawValue) else {
                return .aliyunBailianRealtime
            }
            return provider
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Keys.speechRecognitionProviderKind)
        }
    }

    var speechRecognitionModel: String {
        get { defaults.string(forKey: Keys.speechRecognitionModel) ?? speechRecognitionProviderKind.defaultModel }
        nonmutating set { defaults.set(newValue, forKey: Keys.speechRecognitionModel) }
    }

    var speechRecognitionEndpoint: String {
        get { defaults.string(forKey: Keys.speechRecognitionEndpoint) ?? speechRecognitionProviderKind.defaultEndpoint }
        nonmutating set { defaults.set(newValue, forKey: Keys.speechRecognitionEndpoint) }
    }

    var textAIProviderKind: TextAIProviderKind {
        get {
            guard let rawValue = defaults.string(forKey: Keys.textAIProviderKind),
                  let provider = TextAIProviderKind(rawValue: rawValue) else {
                return .aliyunBailian
            }
            return provider
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Keys.textAIProviderKind)
        }
    }

    var textAIModel: String {
        get { defaults.string(forKey: Keys.textAIModel) ?? textAIProviderKind.defaultModel }
        nonmutating set { defaults.set(newValue, forKey: Keys.textAIModel) }
    }

    var textAIEndpoint: String {
        get { defaults.string(forKey: Keys.textAIEndpoint) ?? textAIProviderKind.defaultEndpoint }
        nonmutating set { defaults.set(newValue, forKey: Keys.textAIEndpoint) }
    }

    private enum Keys {
        static let defaultMode = "defaultMode"
        static let targetLanguage = "targetLanguage"
        static let isHistoryEnabled = "isHistoryEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let hasSeenWelcomeOnboarding = "hasSeenWelcomeOnboarding"
        static let interfaceLanguage = "interfaceLanguage"
        static let textPolishIntensity = "textPolishIntensity"
        static let voiceInputShortcut = "voiceInputShortcut"
        static let speechRecognitionProviderKind = "speechRecognitionProviderKind"
        static let speechRecognitionModel = "speechRecognitionModel"
        static let speechRecognitionEndpoint = "speechRecognitionEndpoint"
        static let textAIProviderKind = "textAIProviderKind"
        static let textAIModel = "textAIModel"
        static let textAIEndpoint = "textAIEndpoint"
    }
}
