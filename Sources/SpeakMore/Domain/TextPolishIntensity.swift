import Foundation

enum TextPolishIntensity: String, CaseIterable, Codable, Equatable {
    case light
    case medium
    case strong

    var title: String {
        switch self {
        case .light:
            "弱"
        case .medium:
            "中"
        case .strong:
            "强"
        }
    }

    var subtitle: String {
        switch self {
        case .light:
            "只做纠错和标点，尽量保留原话"
        case .medium:
            "默认推荐，适度断句和整理"
        case .strong:
            "更主动地分段、提炼和结构化"
        }
    }
}
