import Foundation

@MainActor
final class SpeakMoreController {
    private let state: AppState
    private let settings: AppSettings
    private let realtimeProvider: RealtimeTranscriptionProvider
    private let textProvider: TextTransformProvider
    private let pasteSink: PasteTextSink
    private let networkAvailabilityChecker: NetworkAvailabilityChecking
    private var sessionTask: Task<Void, Never>?
    private var sessionGeneration = 0

    init(
        state: AppState,
        settings: AppSettings,
        realtimeProvider: RealtimeTranscriptionProvider,
        textProvider: TextTransformProvider,
        pasteSink: PasteTextSink = PasteController(),
        networkAvailabilityChecker: NetworkAvailabilityChecking = NetworkAvailabilityChecker()
    ) {
        self.state = state
        self.settings = settings
        self.realtimeProvider = realtimeProvider
        self.textProvider = textProvider
        self.pasteSink = pasteSink
        self.networkAvailabilityChecker = networkAvailabilityChecker
    }

    @discardableResult
    func startSession(selectedText: String?) async -> Int {
        sessionGeneration += 1
        let currentGeneration = sessionGeneration

        if sessionTask != nil {
            realtimeProvider.abort()
            sessionTask?.cancel()
        }

        state.resetForListening(mode: settings.defaultMode, selectedText: selectedText)
        guard networkAvailabilityChecker.isNetworkAvailable else {
            let message = SpeakMoreSessionError.networkUnavailable.localizedDescription
            state.errorMessage = message
            state.status = .failed(message)
            return currentGeneration
        }

        sessionTask = Task { @MainActor in
            var latestTranscript = ""
            let sessionStartedAt = Date()
            var firstTranscriptAt: Date?
            var transformStartedAt: Date?
            do {
                var committedTranscript = ""
                var currentTranscript = ""

                for try await delta in realtimeProvider.startTranscription() {
                    try Task.checkCancellation()
                    guard isCurrentSession(currentGeneration) else { return }

                    if delta.isFinal {
                        if delta.replacesPrevious {
                            committedTranscript = Self.joinTranscript(committedTranscript, delta.text)
                            currentTranscript = ""
                            latestTranscript = committedTranscript
                        } else {
                            committedTranscript = ""
                            currentTranscript = delta.text
                            latestTranscript = currentTranscript
                        }
                    } else if delta.replacesPrevious {
                        currentTranscript = delta.text
                        latestTranscript = Self.joinTranscript(committedTranscript, currentTranscript)
                    } else {
                        currentTranscript += delta.text
                        latestTranscript = Self.joinTranscript(committedTranscript, currentTranscript)
                    }
                    if firstTranscriptAt == nil,
                       Self.normalizedText(latestTranscript) != nil {
                        firstTranscriptAt = Date()
                    }
                    state.rawTranscript = latestTranscript
                }

                try Task.checkCancellation()
                guard isCurrentSession(currentGeneration) else { return }

                guard !latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.status = .idle
                    sessionTask = nil
                    return
                }

                if Self.isRevertLastInsertionCommand(latestTranscript) {
                    state.rawTranscript = latestTranscript
                    do {
                        if try pasteSink.revertLastPastedText() {
                            state.finalText = ""
                            state.status = .idle
                        } else {
                            let message = SpeakMoreSessionError.noRecentInsertionToRevert.localizedDescription
                            state.errorMessage = message
                            state.status = .failed(message)
                        }
                    } catch {
                        state.errorMessage = error.localizedDescription
                        state.status = .failed(error.localizedDescription)
                    }
                    sessionTask = nil
                    return
                }

                if Self.isRevertLastSentenceCommand(latestTranscript) {
                    state.rawTranscript = latestTranscript
                    do {
                        if try pasteSink.revertLastPastedSentence() {
                            state.finalText = ""
                            state.status = .idle
                        } else {
                            let message = SpeakMoreSessionError.noRecentInsertionToRevert.localizedDescription
                            state.errorMessage = message
                            state.status = .failed(message)
                        }
                    } catch {
                        state.errorMessage = error.localizedDescription
                        state.status = .failed(error.localizedDescription)
                    }
                    sessionTask = nil
                    return
                }

                state.status = .transforming
                transformStartedAt = Date()

                let input = VoiceSessionInput(
                    mode: state.mode,
                    rawTranscript: latestTranscript,
                    selectedText: state.selectedText,
                    spokenCommand: nil,
                    targetLanguage: settings.targetLanguage
                )
                let result = try await textProvider.transform(input: input)

                try Task.checkCancellation()
                guard isCurrentSession(currentGeneration) else { return }

                state.rawTranscript = result.rawTranscript
                state.finalText = result.finalText
                state.status = .inserting

                if !result.finalText.isEmpty {
                    try pasteSink.paste(text: result.finalText)
                } else {
                    throw SpeakMoreSessionError.emptyFinalText
                }

                guard isCurrentSession(currentGeneration) else { return }
                recordTiming(
                    startedAt: sessionStartedAt,
                    firstTranscriptAt: firstTranscriptAt,
                    transformStartedAt: transformStartedAt,
                    finishedAt: Date()
                )
                state.status = .idle
                sessionTask = nil
            } catch is CancellationError {
                guard isCurrentSession(currentGeneration) else { return }
                state.status = .idle
                sessionTask = nil
            } catch {
                guard isCurrentSession(currentGeneration) else { return }
                if Self.isNetworkError(error),
                   let recoveredText = Self.normalizedText(latestTranscript) {
                    do {
                        let message = SpeakMoreSessionError.networkInterruptedWithRecoveredText.localizedDescription
                        state.rawTranscript = recoveredText
                        state.finalText = recoveredText
                        state.status = .inserting
                        try pasteSink.paste(text: recoveredText)
                        guard isCurrentSession(currentGeneration) else { return }
                        state.errorMessage = message
                        state.status = .failed(message)
                        sessionTask = nil
                    } catch {
                        state.errorMessage = error.localizedDescription
                        state.status = .failed(error.localizedDescription)
                        sessionTask = nil
                    }
                    return
                }
                if Self.isNetworkError(error) {
                    let message = SpeakMoreSessionError.networkInterrupted.localizedDescription
                    state.errorMessage = message
                    state.status = .failed(message)
                    sessionTask = nil
                    recordTiming(
                        startedAt: sessionStartedAt,
                        firstTranscriptAt: firstTranscriptAt,
                        transformStartedAt: transformStartedAt,
                        finishedAt: Date()
                    )
                    return
                }
                state.errorMessage = error.localizedDescription
                state.status = .failed(error.localizedDescription)
                sessionTask = nil
            }
        }

        return currentGeneration
    }

    @discardableResult
    func switchMode(_ mode: SpeakMoreMode, for generation: Int? = nil) -> Int? {
        guard sessionTask != nil else {
            return nil
        }

        if let generation, !isCurrentSession(generation) {
            return nil
        }

        state.mode = mode
        return sessionGeneration
    }

    func updateSelectedText(_ selectedText: String?, for generation: Int? = nil) {
        guard sessionTask != nil else {
            return
        }

        if let generation, !isCurrentSession(generation) {
            return
        }

        state.selectedText = Self.normalizedText(selectedText)
    }

    func stopSession() {
        realtimeProvider.stop()
        if sessionTask != nil {
            state.status = .finalizing
        }
    }

    func cancelSession() {
        sessionGeneration += 1
        realtimeProvider.abort()
        sessionTask?.cancel()
        sessionTask = nil
        state.rawTranscript = ""
        state.finalText = ""
        state.errorMessage = nil
        state.status = .idle
    }

    private func isCurrentSession(_ generation: Int) -> Bool {
        generation == sessionGeneration
    }

    private func recordTiming(
        startedAt: Date,
        firstTranscriptAt: Date?,
        transformStartedAt: Date?,
        finishedAt: Date
    ) {
        let summary = SessionTimingDiagnostics.makeSummary(
            startedAt: startedAt,
            firstTranscriptAt: firstTranscriptAt,
            transformStartedAt: transformStartedAt,
            finishedAt: finishedAt
        )
        state.performanceHint = summary.visibleHint
        NSLog("\(AppBrand.englishName) session timing \(summary.logLine)")
    }

    private static func joinTranscript(_ committed: String, _ current: String) -> String {
        guard !committed.isEmpty else { return current }
        guard !current.isEmpty else { return committed }
        if endsWithJoinBoundary(committed) || startsWithJoinBoundary(current) {
            return committed + current
        }
        if containsHan(committed) || containsHan(current) {
            return committed + "，" + current
        }
        return committed + " " + current
    }

    private static func startsWithJoinBoundary(_ text: String) -> Bool {
        guard let scalar = text.unicodeScalars.first else { return false }
        return joinBoundaryCharacters.contains(scalar)
    }

    private static func endsWithJoinBoundary(_ text: String) -> Bool {
        guard let scalar = text.unicodeScalars.last else { return false }
        return joinBoundaryCharacters.contains(scalar)
    }

    private static func containsHan(_ text: String) -> Bool {
        text.range(of: "\\p{Han}", options: .regularExpression) != nil
    }

    private static let joinBoundaryCharacters = CharacterSet(charactersIn: " \n\t,，.。!！?？;；:：、)]）}」』”’")

    private static func normalizedText(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func isNetworkError(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain
    }

    private static func isRevertLastInsertionCommand(_ transcript: String) -> Bool {
        let normalized = transcript
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "。.!！?？"))
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        guard !normalized.isEmpty,
              normalized.count <= 14 else {
            return false
        }

        let commandPatterns = [
            #"^(请|麻烦)?(你)?(帮我)?(把)?(刚才|刚刚|上次|上一次|上一段|前一段|上个|前面)(的)?(那段|这段|文字|内容|输入)?(删掉|删除|撤回|取消)$"#,
            #"^(请|麻烦)?(你)?(帮我)?(删掉|删除|撤回|取消)(刚才|刚刚|上次|上一次|上一段|前一段|上个|前面)(的)?(那段|这段|文字|内容|输入)?$"#
        ]

        return commandPatterns.contains { pattern in
            normalized.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private static func isRevertLastSentenceCommand(_ transcript: String) -> Bool {
        let normalized = transcript
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "。.!！?？"))
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        guard !normalized.isEmpty,
              normalized.count <= 22 else {
            return false
        }

        let explicitSentence = #"上一句|上句话|上一句话|前一句|前一句话|最后一句|最后一句话|上个句子|前个句子"#
        let recentSentence = #"(我)?(刚才|刚刚)?(输入的|输的)?(刚才|刚刚)?(输入的|输的)?(那句|那句话|这句|这句话)"#
        let sentenceReference = "(\(explicitSentence)|\(recentSentence))"
        let commandPatterns = [
            #"^(请|麻烦)?(你)?(帮我)?(把)?"# + sentenceReference + #"(删掉|删除|撤回|取消|去掉)$"#,
            #"^(请|麻烦)?(你)?(帮我)?(删掉|删除|撤回|取消|去掉)"# + sentenceReference + #"$"#
        ]

        return commandPatterns.contains { pattern in
            normalized.range(of: pattern, options: .regularExpression) != nil
        }
    }
}

enum SpeakMoreSessionError: LocalizedError, Equatable {
    case noSpeechRecognized
    case emptyFinalText
    case networkUnavailable
    case networkInterrupted
    case networkInterruptedWithRecoveredText
    case noRecentInsertionToRevert

    var errorDescription: String? {
        switch self {
        case .noSpeechRecognized:
            "No speech was recognized. Please try again."
        case .emptyFinalText:
            "AI did not return any text to paste. Please try again."
        case .networkUnavailable:
            "当前网络不可用，请联网后再试。"
        case .networkInterrupted:
            "网络异常，请检查网络后再试。"
        case .networkInterruptedWithRecoveredText:
            "网络异常，已插入已识别的内容，请检查网络后再试。"
        case .noRecentInsertionToRevert:
            "没有找到可撤回的上一段。"
        }
    }
}
