import AppKit
import SwiftUI

struct FloatingWindowView: View {
    @ObservedObject var state: AppState
    let onCancel: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        let presentation = FloatingWindowPresentation(state: state, language: state.interfaceLanguage)

        card(presentation: presentation)
            .frame(
                width: FloatingWindowPresentation.panelWidth,
                height: presentation.visibleCardHeight,
                alignment: .center
            )
            .background(Color.clear)
    }

    private func card(presentation: FloatingWindowPresentation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header(presentation: presentation)

            Divider()

            transcriptArea(presentation: presentation)
                .frame(height: presentation.textViewportHeight)

            if !presentation.audioQualityMeters.isEmpty {
                HStack {
                    Spacer()
                    AudioQualityMeterRow(meters: presentation.audioQualityMeters)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if presentation.secondaryActionTitle != nil {
                Divider()
                secondaryActions(presentation: presentation)
            }
        }
        .padding(18)
        .frame(
            width: FloatingWindowPresentation.cardWidth,
            height: presentation.visibleCardHeight,
            alignment: .topLeading
        )
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: FloatingWindowPresentation.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FloatingWindowPresentation.cornerRadius, style: .continuous)
                .stroke(.primary.opacity(FloatingWindowPresentation.borderStrokeOpacity), lineWidth: 1)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func header(presentation: FloatingWindowPresentation) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusTint(for: state.status).opacity(0.14))
                Image(systemName: statusSystemImage(for: state.status))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(statusTint(for: state.status))
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(AppInterfaceStrings(language: state.interfaceLanguage).modeTitle(state.mode))
                    .font(.system(size: 15, weight: .semibold))
                Text(presentation.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(statusTint(for: state.status))
            }

            Spacer()

            if let shortcutHint = presentation.shortcutHint {
                Text(shortcutHint)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button {
                onCancel()
            } label: {
                Label(presentation.primaryActionTitle, systemImage: presentation.primaryActionSystemImage)
            }
            .keyboardShortcut(.cancelAction)
        }
    }

    private func transcriptArea(presentation: FloatingWindowPresentation) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FloatingWindowPresentation.transcriptTextSpacing) {
                Text(presentation.primaryMessage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !state.finalText.isEmpty {
                    Text(state.finalText)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage = state.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let performanceHint = state.performanceHint {
                    Label(performanceHint, systemImage: "speedometer")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.bottom, FloatingWindowPresentation.textViewportComfortPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }

    private func secondaryActions(presentation: FloatingWindowPresentation) -> some View {
        HStack(spacing: 10) {
            if let secondaryActionTitle = presentation.secondaryActionTitle {
                Button {
                    if presentation.secondaryActionKind == .accessibility {
                        openAccessibilitySettings()
                    } else {
                        onOpenSettings()
                    }
                } label: {
                    Label(secondaryActionTitle, systemImage: presentation.secondaryActionSystemImage)
                }
            }
            Spacer()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func statusTint(for status: SpeakMoreSessionStatus) -> Color {
        switch status {
        case .idle:
            return .secondary
        case .listening:
            return .green
        case .finalizing:
            return .blue
        case .transforming:
            return .purple
        case .inserting:
            return .secondary
        case .noSpeech:
            return .orange
        case .failed:
            return .red
        }
    }

    private func statusSystemImage(for status: SpeakMoreSessionStatus) -> String {
        switch status {
        case .idle:
            return "keyboard"
        case .listening:
            return "waveform"
        case .finalizing:
            return "text.magnifyingglass"
        case .transforming:
            return "wand.and.sparkles"
        case .inserting:
            return "keyboard"
        case .noSpeech:
            return "moon"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
}

private struct AudioQualityMeterRow: View {
    let meters: [AudioQualityMeterPresentation]
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            ForEach(meters) { meter in
                HStack(spacing: 6) {
                    Circle()
                        .fill(color(for: meter))
                        .opacity(meter.status == .good ? 0.58 : (pulse ? 0.92 : 0.62))
                        .frame(width: 7, height: 7)
                        .overlay {
                            Circle()
                                .stroke(
                                    color(for: meter).opacity(meter.status == .good ? 0.16 : 0.24),
                                    lineWidth: 4
                                )
                                .opacity(meter.status == .good ? 0.08 : (pulse ? 0.26 : 0.10))
                        }
                    Text(meter.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(color(for: meter.titleColorRole))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
        .clipShape(Capsule(style: .continuous))
        .onAppear {
            pulse = true
        }
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)
        .animation(.easeInOut(duration: 0.25), value: meters)
    }

    private func color(for meter: AudioQualityMeterPresentation) -> Color {
        switch (meter.kind, meter.status) {
        case (.inputVolume, .low):
            return blend(
                from: MeterColor(red: 0.18, green: 0.66, blue: 0.32),
                to: MeterColor(red: 0.96, green: 0.53, blue: 0.16),
                amount: meter.severity
            )
        case (.inputVolume, .good):
            return .green
        case (.inputVolume, .high):
            return blend(
                from: MeterColor(red: 0.18, green: 0.66, blue: 0.32),
                to: MeterColor(red: 0.04, green: 0.42, blue: 0.22),
                amount: meter.severity
            )
        case (.backgroundNoise, .low):
            return .green
        case (.backgroundNoise, .good):
            return .green
        case (.backgroundNoise, .high):
            return blend(
                from: MeterColor(red: 0.18, green: 0.66, blue: 0.32),
                to: MeterColor(red: 0.96, green: 0.53, blue: 0.16),
                amount: meter.severity
            )
        }
    }

    private func blend(from: MeterColor, to: MeterColor, amount: Double) -> Color {
        let clamped = min(1, max(0, amount))
        return Color(
            red: from.red + (to.red - from.red) * clamped,
            green: from.green + (to.green - from.green) * clamped,
            blue: from.blue + (to.blue - from.blue) * clamped
        )
    }

    private func color(for role: AudioQualityMeterTitleColorRole) -> Color {
        switch role {
        case .secondary:
            return .secondary
        }
    }
}

private struct MeterColor {
    let red: Double
    let green: Double
    let blue: Double
}

struct AudioQualityMeterPresentation: Identifiable, Equatable {
    let kind: AudioQualityMeterKind
    let title: String
    let status: AudioQualityMeterStatus
    let severity: Double
    let titleColorRole: AudioQualityMeterTitleColorRole = .secondary

    var id: AudioQualityMeterKind { kind }
}

enum AudioQualityMeterTitleColorRole: Equatable {
    case secondary
}

struct FloatingWindowPresentation {
    enum SecondaryActionKind {
        case accessibility
        case modelSettings
    }

    enum AudioQualityMeterPlacement: Equatable {
        case bottomTrailing
    }

    let statusText: String
    let primaryMessage: String
    let shortcutHint: String?
    let primaryActionTitle: String
    let primaryActionSystemImage: String
    let secondaryActionTitle: String?
    let secondaryActionKind: SecondaryActionKind?
    let secondaryActionSystemImage: String
    let audioQualityMeters: [AudioQualityMeterPresentation]
    let audioQualityMeterPlacement: AudioQualityMeterPlacement
    let cardHeight: CGFloat
    let visibleCardHeight: CGFloat
    let textViewportHeight: CGFloat
    let shadowCardHeight: CGFloat
    let preferredSize: CGSize

    static let shadowOutset: CGFloat = 48
    static let shadowOpacity: Float = 0.10
    static let shadowRadius: CGFloat = 30
    static let shadowYOffset: CGFloat = -8
    static let borderStrokeOpacity: Double = 0.045
    static let cornerRadius: CGFloat = 18
    static let cardWidth: CGFloat = 660
    static let minimumCardHeight: CGFloat = 166
    static let maximumCardHeight: CGFloat = 680
    static let minimumTextLineCount = 3
    static let textContentWidth: CGFloat = cardWidth - 36
    static let textLineHeight: CGFloat = 24
    static let minimumTextViewportHeight = CGFloat(minimumTextLineCount) * textLineHeight
    static let transcriptTextSpacing: CGFloat = 10
    static let textViewportComfortPadding: CGFloat = 22
    static let textMeasurementSafetyScale: CGFloat = 1.08
    static let baseChromeHeight: CGFloat = 93
    static let secondaryActionChromeHeight: CGFloat = 58
    static let audioQualityChromeHeight: CGFloat = 34
    static let panelWidth: CGFloat = cardWidth
    static let minimumPanelHeight: CGFloat = minimumCardHeight
    static let maximumPanelHeight: CGFloat = maximumCardHeight
    static let initialPanelSize = CGSize(width: panelWidth, height: minimumPanelHeight)

    @MainActor
    init(state: AppState, language: AppLanguage = .simplifiedChinese) {
        let strings = AppInterfaceStrings(language: language)
        statusText = strings.statusPresentation(status: state.status).buttonTitle
            .replacingOccurrences(of: "\(AppBrand.englishName) · ", with: "")
        primaryMessage = Self.makePrimaryMessage(state: state, strings: strings)
        shortcutHint = Self.makeShortcutHint(state.status, strings: strings)
        primaryActionTitle = Self.makePrimaryActionTitle(state.status, strings: strings)
        primaryActionSystemImage = Self.isFailed(state.status) ? "xmark" : "stop.fill"
        let secondaryAction = Self.makeSecondaryAction(errorMessage: state.errorMessage, strings: strings)
        secondaryActionTitle = secondaryAction?.title
        secondaryActionKind = secondaryAction?.kind
        secondaryActionSystemImage = secondaryAction?.systemImage ?? "gearshape"
        audioQualityMeters = Self.makeAudioQualityMeters(
            status: state.status,
            snapshot: state.audioQualitySnapshot,
            strings: strings
        )
        audioQualityMeterPlacement = .bottomTrailing
        cardHeight = Self.makeCardHeight(
            primaryMessage: primaryMessage,
            finalText: state.finalText,
            errorMessage: state.errorMessage,
            showsAudioQualityMeters: !audioQualityMeters.isEmpty,
            showsSecondaryAction: secondaryAction != nil
        )
        visibleCardHeight = Self.makeVisibleCardHeight(status: state.status, cardHeight: cardHeight)
        textViewportHeight = Self.makeTextViewportHeight(
            cardHeight: visibleCardHeight,
            showsAudioQualityMeters: !audioQualityMeters.isEmpty,
            showsSecondaryAction: secondaryAction != nil
        )
        shadowCardHeight = visibleCardHeight
        preferredSize = Self.makePreferredSize(
            primaryMessage: primaryMessage,
            finalText: state.finalText,
            errorMessage: state.errorMessage,
            showsAudioQualityMeters: !audioQualityMeters.isEmpty,
            showsSecondaryAction: secondaryAction != nil
        )
    }

    static func makePreferredSize(
        primaryMessage: String,
        finalText: String = "",
        errorMessage: String? = nil,
        showsAudioQualityMeters: Bool = false,
        showsSecondaryAction: Bool = false
    ) -> CGSize {
        CGSize(
            width: panelWidth,
            height: makeCardHeight(
                primaryMessage: primaryMessage,
                finalText: finalText,
                errorMessage: errorMessage,
                showsAudioQualityMeters: showsAudioQualityMeters,
                showsSecondaryAction: showsSecondaryAction
            )
        )
    }

    static func makeCardHeight(
        primaryMessage: String,
        finalText: String = "",
        errorMessage: String? = nil,
        showsAudioQualityMeters: Bool = false,
        showsSecondaryAction: Bool = false
    ) -> CGFloat {
        let textHeight = max(
            minimumTextViewportHeight,
            measuredTranscriptContentHeight(
                primaryMessage: primaryMessage,
                finalText: finalText,
                errorMessage: errorMessage
            )
        )
        let proposedHeight = ceil(fixedChromeHeight(
            showsAudioQualityMeters: showsAudioQualityMeters,
            showsSecondaryAction: showsSecondaryAction
        ) + textHeight)

        return min(max(proposedHeight, minimumCardHeight), maximumCardHeight)
    }

    private static func makeTextViewportHeight(
        cardHeight: CGFloat,
        showsAudioQualityMeters: Bool,
        showsSecondaryAction: Bool
    ) -> CGFloat {
        max(
            minimumTextViewportHeight,
            cardHeight - fixedChromeHeight(
                showsAudioQualityMeters: showsAudioQualityMeters,
                showsSecondaryAction: showsSecondaryAction
            )
        )
    }

    private static func fixedChromeHeight(
        showsAudioQualityMeters: Bool,
        showsSecondaryAction: Bool
    ) -> CGFloat {
        baseChromeHeight
            + (showsAudioQualityMeters ? audioQualityChromeHeight : 0)
            + (showsSecondaryAction ? secondaryActionChromeHeight : 0)
    }

    private static func makeAudioQualityMeters(
        status: SpeakMoreSessionStatus,
        snapshot: AudioQualitySnapshot?,
        strings: AppInterfaceStrings
    ) -> [AudioQualityMeterPresentation] {
        if let snapshot {
            return [
                .init(
                    kind: .inputVolume,
                    title: strings.audioQualityMeterTitle(.inputVolume),
                    status: snapshot.meterStatus(for: .inputVolume),
                    severity: snapshot.meterSeverity(for: .inputVolume)
                ),
                .init(
                    kind: .backgroundNoise,
                    title: strings.audioQualityMeterTitle(.backgroundNoise),
                    status: snapshot.meterStatus(for: .backgroundNoise),
                    severity: snapshot.meterSeverity(for: .backgroundNoise)
                )
            ]
        }

        guard shouldReserveAudioQualityMeters(status: status) else {
            return []
        }

        return [
            .init(
                kind: .inputVolume,
                title: strings.audioQualityMeterTitle(.inputVolume),
                status: .good,
                severity: 0
            ),
            .init(
                kind: .backgroundNoise,
                title: strings.audioQualityMeterTitle(.backgroundNoise),
                status: .good,
                severity: 0
            )
        ]
    }

    private static func shouldReserveAudioQualityMeters(status: SpeakMoreSessionStatus) -> Bool {
        switch status {
        case .listening, .finalizing:
            true
        case .idle, .transforming, .inserting, .noSpeech, .failed:
            false
        }
    }

    private static func makeVisibleCardHeight(status: SpeakMoreSessionStatus, cardHeight: CGFloat) -> CGFloat {
        switch status {
        case .listening, .finalizing, .transforming:
            return cardHeight
        case .inserting:
            return minimumCardHeight
        case .idle, .noSpeech:
            return minimumCardHeight
        case .failed:
            return cardHeight
        }
    }

    private static func measuredTextHeight(_ text: String, fontSize: CGFloat) -> CGFloat {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return 0
        }

        let font = NSFont.systemFont(ofSize: fontSize)
        let boundingRect = NSString(string: trimmedText).boundingRect(
            with: CGSize(width: textContentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )

        return ceil(boundingRect.height * textMeasurementSafetyScale)
    }

    private static func measuredTranscriptContentHeight(
        primaryMessage: String,
        finalText: String,
        errorMessage: String?
    ) -> CGFloat {
        let measuredHeights = [
            measuredTextHeight(primaryMessage, fontSize: 16),
            measuredTextHeight(finalText, fontSize: 14),
            measuredTextHeight(errorMessage ?? "", fontSize: 13)
        ].filter { $0 > 0 }

        guard !measuredHeights.isEmpty else {
            return 0
        }

        let spacing = CGFloat(measuredHeights.count - 1) * transcriptTextSpacing
        return measuredHeights.reduce(0, +) + spacing + textViewportComfortPadding
    }

    private static func makeShortcutHint(_ status: SpeakMoreSessionStatus, strings: AppInterfaceStrings) -> String? {
        switch status {
        case .listening, .finalizing:
            strings.shortcutHint
        case .idle, .transforming, .inserting, .noSpeech, .failed:
            nil
        }
    }

    @MainActor
    private static func makePrimaryMessage(state: AppState, strings: AppInterfaceStrings) -> String {
        if !state.rawTranscript.isEmpty {
            return state.rawTranscript
        }

        switch state.status {
        case .idle:
            return strings.readyMessage
        case .listening:
            return strings.listeningMessage
        case .finalizing:
            return strings.finalizingMessage
        case .transforming:
            return strings.transformingMessage
        case .inserting:
            return strings.readyMessage
        case .noSpeech:
            return strings.noSpeechMessage
        case .failed:
            return strings.failedMessage
        }
    }

    private static func makePrimaryActionTitle(_ status: SpeakMoreSessionStatus, strings: AppInterfaceStrings) -> String {
        switch status {
        case .failed, .idle, .noSpeech:
            return strings.close
        case .inserting:
            return strings.close
        case .listening, .finalizing, .transforming:
            return strings.cancel
        }
    }

    private static func makeSecondaryAction(
        errorMessage: String?,
        strings: AppInterfaceStrings
    ) -> (title: String, kind: SecondaryActionKind, systemImage: String)? {
        guard let errorMessage else {
            return nil
        }

        if errorMessage.localizedCaseInsensitiveContains("Accessibility permission")
            || errorMessage.contains("辅助功能") {
            return (strings.openAccessibilitySettings, .accessibility, "gearshape")
        }

        if errorMessage.localizedCaseInsensitiveContains("quota")
            || errorMessage.localizedCaseInsensitiveContains("balance")
            || errorMessage.localizedCaseInsensitiveContains("billing")
            || errorMessage.contains("额度")
            || errorMessage.contains("余额")
            || errorMessage.contains("欠费")
            || errorMessage.contains("429")
            || errorMessage.contains("402") {
            return (strings.openModelSettings, .modelSettings, "key")
        }

        return nil
    }

    private static func isFailed(_ status: SpeakMoreSessionStatus) -> Bool {
        if case .failed = status {
            return true
        }

        return false
    }
}
