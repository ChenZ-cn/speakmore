import Foundation

enum SpeakMoreMode: String, CaseIterable, Codable, Equatable {
    case auto
    case dictate
    case translate
    case polish
    case askSelectedText

    var title: String {
        switch self {
        case .auto: "自动模式"
        case .dictate: "直接听写"
        case .translate: "翻译模式"
        case .polish: "润色模式"
        case .askSelectedText: "对选中文字提问"
        }
    }

    var subtitle: String {
        switch self {
        case .auto: "自动判断是直接输入、整理、分点、润色还是翻译"
        case .dictate: "轻度清理口语，尽量保留原话"
        case .translate: "把语音翻译成目标语言"
        case .polish: "把粗糙口语改成可直接发送的文字"
        case .askSelectedText: "对当前选中的文字执行语音指令"
        }
    }
}
