import Foundation

enum AppLanguage: String, CaseIterable, Codable, Equatable {
    case system
    case simplifiedChinese
    case english
    case japanese
    case korean
    case french
    case german
    case spanish
    case portuguese
    case italian
    case russian
    case arabic
    case hindi
    case indonesian
    case vietnamese
    case thai

    var title: String {
        switch self {
        case .system: "跟随系统"
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .french: "Français"
        case .german: "Deutsch"
        case .spanish: "Español"
        case .portuguese: "Português"
        case .italian: "Italiano"
        case .russian: "Русский"
        case .arabic: "العربية"
        case .hindi: "हिन्दी"
        case .indonesian: "Bahasa Indonesia"
        case .vietnamese: "Tiếng Việt"
        case .thai: "ไทย"
        }
    }
}
