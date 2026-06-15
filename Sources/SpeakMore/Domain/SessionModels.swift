import Foundation

enum SpeakMoreSessionStatus: Equatable {
    case idle
    case listening
    case finalizing
    case transforming
    case inserting
    case noSpeech
    case failed(String)
}

struct TranscriptDelta: Equatable {
    let text: String
    let isFinal: Bool
    let replacesPrevious: Bool

    init(text: String, isFinal: Bool, replacesPrevious: Bool = false) {
        self.text = text
        self.isFinal = isFinal
        self.replacesPrevious = replacesPrevious
    }
}

struct VoiceSessionInput: Equatable {
    let mode: SpeakMoreMode
    let rawTranscript: String
    let selectedText: String?
    let spokenCommand: String?
    let targetLanguage: String
}

struct VoiceSessionResult: Equatable {
    let rawTranscript: String
    let finalText: String
    let shouldReplaceSelection: Bool
}
