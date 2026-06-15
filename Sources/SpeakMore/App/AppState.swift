import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var mode: SpeakMoreMode = .dictate
    @Published var status: SpeakMoreSessionStatus = .idle
    @Published var rawTranscript: String = ""
    @Published var finalText: String = ""
    @Published var selectedText: String?
    @Published var errorMessage: String?
    @Published var interfaceLanguage: AppLanguage = .system
    @Published var audioQualityIssue: AudioQualityIssue?
    @Published var audioQualitySnapshot: AudioQualitySnapshot?
    @Published var performanceHint: String?

    func resetForListening(mode: SpeakMoreMode, selectedText: String?) {
        self.mode = mode
        self.status = .listening
        self.rawTranscript = ""
        self.finalText = ""
        self.selectedText = selectedText
        self.errorMessage = nil
        self.audioQualityIssue = nil
        self.audioQualitySnapshot = nil
        self.performanceHint = nil
    }
}
