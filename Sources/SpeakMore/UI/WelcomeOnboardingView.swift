import SwiftUI

struct WelcomeOnboardingView: View {
    private let onFinish: @MainActor () -> Void
    @State private var showsHome = true
    @State private var homeIsVisible = false
    @State private var selectedStep = 0
    @State private var selectedLanguage: AppLanguage = .simplifiedChinese

    init(onFinish: @escaping @MainActor () -> Void) {
        self.onFinish = onFinish
    }

    private var copy: WelcomeLocalizedCopy {
        WelcomeLocalizedCopy.copy(for: selectedLanguage)
    }

    var body: some View {
        ZStack {
            if showsHome {
                WelcomeHomePrototypeView(
                    isVisible: homeIsVisible,
                    onNext: showGuide
                )
                .transition(.opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.78, dampingFraction: 0.82).delay(0.06)) {
                        homeIsVisible = true
                    }
                }
            } else {
                WelcomeGuidePrototypeView(
                    copy: copy,
                    selectedStep: $selectedStep,
                    selectedLanguage: $selectedLanguage,
                    onBackHome: showHome,
                    onFinish: onFinish
                )
                .transition(.opacity)
            }
        }
        .frame(width: 1080, height: 716)
    }

    private func showGuide() {
        withAnimation(.easeInOut(duration: 0.22)) {
            showsHome = false
        }
    }

    private func showHome() {
        withAnimation(.easeInOut(duration: 0.22)) {
            selectedStep = 0
            showsHome = true
            homeIsVisible = true
        }
    }
}

private struct WelcomeHomePrototypeView: View {
    let isVisible: Bool
    let onNext: () -> Void

    var body: some View {
        OnboardingCanvas(width: 1080, height: 716) {
            ZStack {
                WelcomeGrid()

                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    ZStack {
                        Capsule()
                            .fill(WelcomePalette.ink.opacity(isVisible ? 0.055 : 0))
                            .frame(width: 360, height: 118)
                            .blur(radius: 30)
                            .scaleEffect(isVisible ? 1 : 0.72)

                        HStack(alignment: .center, spacing: 28) {
                            SpeakMoreNativeIcon(size: 124)
                                .shadow(color: WelcomePalette.ink.opacity(0.20), radius: 18, y: 14)
                                .scaleEffect(isVisible ? 1 : 0.70)
                                .blur(radius: isVisible ? 0 : 10)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Speak ")
                                    .foregroundStyle(WelcomePalette.ink)
                                + Text("More")
                                    .foregroundStyle(Color(red: 0.23, green: 0.26, blue: 0.30))

                                Text("多说有益，用说话完成输入。")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(WelcomePalette.muted)
                                    .opacity(isVisible ? 1 : 0)
                                    .offset(y: isVisible ? 0 : 10)
                            }
                            .font(.system(size: 78, weight: .heavy, design: .default))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .opacity(isVisible ? 1 : 0)
                            .offset(x: isVisible ? 0 : -42)
                        }
                        .offset(x: isVisible ? 0 : 96)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)

                    Button(action: onNext) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(WelcomePalette.accentStrong, in: Circle())
                            .shadow(color: Color.black.opacity(0.16), radius: 18, y: 10)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("下一步")
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 10)

                    Spacer(minLength: 42)
                }
                .padding(.horizontal, 48)
            }
        }
    }
}

private struct WelcomeGuidePrototypeView: View {
    let copy: WelcomeLocalizedCopy
    @Binding var selectedStep: Int
    @Binding var selectedLanguage: AppLanguage
    let onBackHome: () -> Void
    let onFinish: @MainActor () -> Void

    private var currentStep: WelcomeStepCopy {
        copy.steps[selectedStep]
    }

    var body: some View {
        OnboardingCanvas(width: 1080, height: 716) {
            HStack(spacing: 0) {
                sidebar

                Divider()
                    .overlay(WelcomePalette.line)

                VStack(spacing: 0) {
                    content
                    footer
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(WelcomePalette.window)
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 12) {
                SpeakMoreNativeIcon(size: 46)
                    .shadow(color: Color.black.opacity(0.14), radius: 12, y: 6)

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppBrand.englishName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(WelcomePalette.text)
                    Text(copy.brandTagline)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WelcomePalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 8) {
                ForEach(copy.steps.indices, id: \.self) { index in
                    StepButton(
                        index: index,
                        step: copy.steps[index],
                        isSelected: index == selectedStep
                    ) {
                        selectedStep = index
                    }
                }
            }

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                Text(copy.sidebarNote)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WelcomePalette.muted)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(WelcomePalette.line, lineWidth: 1)
                    )

                WelcomeLanguagePicker(
                    label: copy.languageLabel,
                    selectedLanguage: $selectedLanguage
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(width: 292)
        .background(WelcomePalette.sidebar)
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 28) {
            VStack(alignment: .leading, spacing: 0) {
                Text(currentStep.title)
                    .font(.system(size: 42, weight: .heavy))
                    .lineSpacing(2)
                    .foregroundStyle(WelcomePalette.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 18)

                Text(currentStep.lead)
                    .font(.system(size: 17, weight: .regular))
                    .lineSpacing(7)
                    .foregroundStyle(WelcomePalette.bodyText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(currentStep.highlights, id: \.self) { highlight in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(WelcomePalette.accent)
                                .frame(width: 8, height: 8)
                                .padding(.top, 8)

                            Text(highlight)
                                .font(.system(size: 14, weight: .regular))
                                .lineSpacing(4)
                                .foregroundStyle(Color(red: 0.24, green: 0.27, blue: 0.30))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 28)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            WelcomeDemoPreview(
                copy: copy,
                stepIndex: selectedStep,
                onOpenSettings: onFinish
            )
            .frame(maxWidth: 360)
        }
        .padding(.horizontal, 46)
        .padding(.vertical, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(copy.steps.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(index <= selectedStep ? WelcomePalette.accent : Color(red: 0.80, green: 0.84, blue: 0.87))
                        .frame(width: 34, height: 4)
                        .accessibilityIdentifier(index <= selectedStep ? "bar active" : "bar")
                }
            }
            .accessibilityLabel(copy.progressLabel)

            Spacer()

            Button(copy.skipButtonTitle, action: onFinish)
                .buttonStyle(WelcomeFooterButtonStyle(kind: .ghost))

            Button(copy.previousButtonTitle) {
                if selectedStep == 0 {
                    onBackHome()
                } else {
                    selectedStep -= 1
                }
            }
            .buttonStyle(WelcomeFooterButtonStyle(kind: .secondary))

            Button(selectedStep == copy.steps.count - 1 ? copy.startSetupButtonTitle : copy.nextButtonTitle) {
                if selectedStep == copy.steps.count - 1 {
                    onFinish()
                } else {
                    selectedStep += 1
                }
            }
            .buttonStyle(WelcomeFooterButtonStyle(kind: .primary))
        }
        .padding(.horizontal, 24)
        .frame(height: 68)
        .background(Color(red: 0.976, green: 0.984, blue: 0.988).opacity(0.92))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(WelcomePalette.line)
                .frame(height: 1)
        }
    }
}

private struct StepButton: View {
    let index: Int
    let step: WelcomeStepCopy
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? .white : WelcomePalette.muted)
                    .frame(width: 26, height: 26)
                    .background(isSelected ? WelcomePalette.accent : Color.clear, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? WelcomePalette.accent : WelcomePalette.lineStrong, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.sidebarTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WelcomePalette.text)
                    Text(step.sidebarSubtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(WelcomePalette.muted)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
            .background(isSelected ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? WelcomePalette.accent.opacity(0.28) : Color.clear, lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct WelcomeLanguagePicker: View {
    let label: String
    @Binding var selectedLanguage: AppLanguage

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    selectedLanguage = language
                } label: {
                    HStack {
                        Text(language.title)
                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WelcomePalette.muted)
                    Text(selectedLanguage.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WelcomePalette.text)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WelcomePalette.muted)
            }
            .frame(height: 44)
            .padding(.horizontal, 10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(WelcomePalette.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct WelcomeDemoPreview: View {
    let copy: WelcomeLocalizedCopy
    let stepIndex: Int
    let onOpenSettings: @MainActor () -> Void

    var body: some View {
        Group {
            switch stepIndex {
            case 0:
                OverviewDemo(copy: copy)
            case 1:
                UsageDemo(copy: copy)
            case 2:
                ModesDemo(copy: copy)
            default:
                ConfigDemo(copy: copy, onOpenSettings: onOpenSettings)
            }
        }
    }
}

private struct OverviewDemo: View {
    let copy: WelcomeLocalizedCopy

    var body: some View {
        DemoCard {
            VStack(spacing: 0) {
                MiniHeader(left: copy.overviewHeaderLeft, right: copy.overviewHeaderRight)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(WelcomePalette.accent)
                            .frame(width: 2, height: 18)
                        Text(copy.overviewCursor)
                            .font(.system(size: 13))
                            .foregroundStyle(WelcomePalette.soft)
                    }
                    .frame(height: 38)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(WelcomePalette.line, lineWidth: 1)
                    )

                    Text(copy.overviewOutput)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .foregroundStyle(Color(red: 0.24, green: 0.27, blue: 0.30))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(WelcomePalette.accentSoft, in: UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 7, topTrailingRadius: 7))
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(WelcomePalette.accent)
                                .frame(width: 3)
                        }
                }
                .padding(14)
            }
            .background(Color(red: 0.976, green: 0.984, blue: 0.988), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(WelcomePalette.line, lineWidth: 1)
            )
        }
    }
}

private struct UsageDemo: View {
    let copy: WelcomeLocalizedCopy

    var body: some View {
        DemoCard {
            VStack(spacing: 0) {
                MiniHeader(left: copy.usageHeaderLeft, right: copy.usageHeaderRight)

                VStack(spacing: 8) {
                    ForEach(copy.usageSteps.indices, id: \.self) { index in
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WelcomePalette.muted)
                                .frame(width: 22, height: 22)
                                .background(WelcomePalette.accentSoft, in: Circle())

                            VStack(alignment: .leading, spacing: 1) {
                                Text(copy.usageSteps[index].0)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(WelcomePalette.text)
                                Text(copy.usageSteps[index].1)
                                    .font(.system(size: 11))
                                    .foregroundStyle(WelcomePalette.muted)
                            }

                            Spacer()

                            if index == 1 {
                                Text("Control")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(WelcomePalette.accentStrong)
                                    .frame(minWidth: 64, minHeight: 28)
                                    .padding(.horizontal, 10)
                                    .background(LinearGradient(colors: [.white, Color(red: 0.94, green: 0.95, blue: 0.95)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .stroke(WelcomePalette.lineStrong, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(index == 2 ? WelcomePalette.accentSoft : Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(WelcomePalette.line, lineWidth: 1)
                        )
                    }
                }
                .padding(14)
            }
            .background(Color(red: 0.976, green: 0.984, blue: 0.988), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(WelcomePalette.line, lineWidth: 1)
            )
        }
    }
}

private struct ModesDemo: View {
    let copy: WelcomeLocalizedCopy

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(copy.modes.indices, id: \.self) { index in
                ModeTile(
                    icon: ["sparkles", "mic", "character.book.closed", "pencil", "text.bubble"][index],
                    title: copy.modes[index].0,
                    subtitle: copy.modes[index].1
                )
                .gridCellColumns(index == 4 ? 2 : 1)
            }
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(WelcomePalette.line, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, y: 10)
    }
}

private struct ConfigDemo: View {
    let copy: WelcomeLocalizedCopy
    let onOpenSettings: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 0) {
                ForEach(copy.configRows.indices, id: \.self) { index in
                    HStack(spacing: 10) {
                        Image(systemName: ["mic", "text.alignleft", "waveform", "figure.walk"][index])
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(WelcomePalette.accentStrong)
                            .frame(width: 34, height: 34)
                            .background(WelcomePalette.accentSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(WelcomePalette.line, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(copy.configRows[index].0)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(WelcomePalette.text)
                            Text(copy.configRows[index].1)
                                .font(.system(size: 12))
                                .foregroundStyle(WelcomePalette.muted)
                        }

                        Spacer()

                        Button(copy.configRows[index].2, action: onOpenSettings)
                            .buttonStyle(index < 2 ? ConfigStatusButtonStyle(kind: .todo) : ConfigStatusButtonStyle(kind: .ready))
                    }
                    .padding(.leading, 18)
                    .padding(.trailing, 28)
                    .frame(minHeight: 56)

                    if index < copy.configRows.count - 1 {
                        Divider()
                            .overlay(WelcomePalette.line)
                    }
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(WelcomePalette.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 18, y: 10)

            Text(copy.configNote)
                .font(.system(size: 11))
                .lineSpacing(3)
                .foregroundStyle(WelcomePalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
        }
    }
}

private struct ModeTile: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WelcomePalette.accentStrong)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WelcomePalette.text)
                Text(subtitle)
                    .font(.system(size: 12))
                    .lineSpacing(3)
                    .foregroundStyle(WelcomePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 78, alignment: .top)
        .padding(16)
        .background(Color(red: 0.986, green: 0.990, blue: 0.994), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(WelcomePalette.line, lineWidth: 1)
        )
    }
}

private struct DemoCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(WelcomePalette.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 18, y: 10)
    }
}

private struct MiniHeader: View {
    let left: String
    let right: String

    var body: some View {
        HStack {
            Text(left)
            Spacer()
            Text(right)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(WelcomePalette.muted)
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(Color(red: 0.976, green: 0.984, blue: 0.988))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(WelcomePalette.line)
                .frame(height: 1)
        }
    }
}

private struct OnboardingCanvas<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
        .frame(width: width)
        .frame(height: height)
        .background(WelcomePalette.window)
    }
}

private struct WelcomeGrid: View {
    var body: some View {
        Canvas { context, size in
            let lineColor = Color(red: 0.83, green: 0.85, blue: 0.88).opacity(0.30)
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += 88
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += 88
            }
            context.stroke(path, with: .color(lineColor), lineWidth: 1)
        }
        .background(WelcomePalette.window)
    }
}

private struct WelcomePageBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.42),
                WelcomePalette.page
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct SpeakMoreNativeIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.03, green: 0.08, blue: 0.13),
                            Color(red: 0.01, green: 0.03, blue: 0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(alignment: .center, spacing: size * 0.035) {
                VoiceBar(height: 0.28, size: size)
                VoiceBar(height: 0.46, size: size)
                VoiceBar(height: 0.66, size: size)
                VoiceBar(height: 0.44, size: size)
                RoundedRectangle(cornerRadius: size * 0.018, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.86, blue: 0.25),
                                Color(red: 1.0, green: 0.63, blue: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.06, height: size * 0.34)
            }

            Image(systemName: "sparkle")
                .font(.system(size: size * 0.15, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.83, blue: 0.22))
                .offset(x: size * 0.25, y: -size * 0.25)
        }
        .frame(width: size, height: size)
    }
}

private struct VoiceBar: View {
    let height: CGFloat
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.27, green: 0.95, blue: 0.87),
                        Color(red: 0.05, green: 0.70, blue: 0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.06, height: size * height)
    }
}

private struct WelcomeFooterButtonStyle: ButtonStyle {
    enum Kind {
        case ghost
        case secondary
        case primary
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(minHeight: 36)
            .padding(.horizontal, 14)
            .background(background, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
    }

    private var foreground: Color {
        switch kind {
        case .ghost: WelcomePalette.muted
        case .secondary: WelcomePalette.text
        case .primary: .white
        }
    }

    private var background: Color {
        switch kind {
        case .ghost: .clear
        case .secondary: .white
        case .primary: WelcomePalette.accent
        }
    }

    private var border: Color {
        switch kind {
        case .ghost: .clear
        case .secondary: WelcomePalette.lineStrong
        case .primary: WelcomePalette.accentStrong
        }
    }
}

private struct ConfigStatusButtonStyle: ButtonStyle {
    enum Kind {
        case todo
        case ready
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(kind == .todo ? .white : WelcomePalette.soft)
            .frame(minHeight: 28)
            .padding(.horizontal, kind == .todo ? 12 : 0)
            .background(kind == .todo ? WelcomePalette.accentStrong : .clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private enum WelcomePalette {
    static let page = Color(red: 0.94, green: 0.95, blue: 0.96)
    static let window = Color(red: 0.984, green: 0.984, blue: 0.988)
    static let sidebar = Color(red: 0.965, green: 0.969, blue: 0.973)
    static let line = Color(red: 0.85, green: 0.87, blue: 0.89)
    static let lineStrong = Color(red: 0.68, green: 0.71, blue: 0.75)
    static let text = Color(red: 0.13, green: 0.15, blue: 0.17)
    static let bodyText = Color(red: 0.28, green: 0.31, blue: 0.35)
    static let muted = Color(red: 0.38, green: 0.42, blue: 0.46)
    static let soft = Color(red: 0.55, green: 0.58, blue: 0.62)
    static let ink = Color(red: 0.03, green: 0.07, blue: 0.13)
    static let accent = Color(red: 0.37, green: 0.41, blue: 0.45)
    static let accentStrong = Color(red: 0.20, green: 0.23, blue: 0.26)
    static let accentSoft = Color(red: 0.933, green: 0.941, blue: 0.949)
}

private struct WelcomeLocalizedCopy {
    let titlebar: String
    let brandTagline: String
    let sidebarNote: String
    let languageLabel: String
    let progressLabel: String
    let skipButtonTitle: String
    let previousButtonTitle: String
    let nextButtonTitle: String
    let startSetupButtonTitle: String
    let overviewHeaderLeft: String
    let overviewHeaderRight: String
    let overviewCursor: String
    let overviewOutput: String
    let usageHeaderLeft: String
    let usageHeaderRight: String
    let usageSteps: [(String, String)]
    let modes: [(String, String)]
    let configRows: [(String, String, String)]
    let configNote: String
    let steps: [WelcomeStepCopy]

    static func copy(for language: AppLanguage) -> WelcomeLocalizedCopy {
        switch resolved(language) {
        case .simplifiedChinese:
            return chinese
        default:
            return english
        }
    }

    private static func resolved(_ language: AppLanguage) -> AppLanguage {
        if language != .system {
            return language
        }

        let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
        if preferredLanguage.hasPrefix("zh") {
            return .simplifiedChinese
        }
        return .english
    }

    private static let chinese = WelcomeLocalizedCopy(
        titlebar: "SpeakMore 入门教程",
        brandTagline: "多说有益，用说话完成输入。",
        sidebarNote: "这个页面只在首次安装后自动出现。以后可以从菜单栏再次打开入门教程。",
        languageLabel: "界面语言",
        progressLabel: "教程进度",
        skipButtonTitle: "稍后再说",
        previousButtonTitle: "上一步",
        nextButtonTitle: "下一步",
        startSetupButtonTitle: "开始配置",
        overviewHeaderLeft: "当前应用",
        overviewHeaderRight: "准备就绪",
        overviewCursor: "光标在这里，准备输入...",
        overviewOutput: "明天下午我可以参加会议。我们可以先确认目标，再讨论技术方案。",
        usageHeaderLeft: "按住之后",
        usageHeaderRight: "正在听你说话",
        usageSteps: [
            ("放好光标", "任意聊天、邮件或文档输入框。"),
            ("按住说话", "说完再松开按键。"),
            ("自动写入", "识别并整理后，结果进入当前输入框。")
        ],
        modes: [
            ("自动", "自动判断最合适的输出方式。"),
            ("听写", "轻度清理口语，保留原话。"),
            ("翻译", "翻译成你设置的目标语言。"),
            ("润色", "把粗糙口语改成可发送文本。"),
            ("问选中内容", "对选中文字进行总结、解释、改写或翻译。")
        ],
        configRows: [
            ("语音识别 API Key", "用于实时转写。", "配置"),
            ("文字 AI API Key", "用于整理、翻译和润色。", "配置"),
            ("麦克风权限", "允许应用听到你说话。", "系统询问"),
            ("辅助功能权限", "用于快捷键和自动粘贴。", "系统设置")
        ],
        configNote: "我们会提供 2000 字输出和 10 分钟语音识别的免费试用；用完后，可以填写自己的 API Key 继续使用。",
        steps: [
            WelcomeStepCopy(
                sidebarTitle: "认识它",
                sidebarSubtitle: "它会把语音变成可发送文字。",
                title: "把说出来的话，变成能直接发送的文字。",
                lead: "SpeakMore 是一个 macOS 菜单栏语音输入工具。你可以在任何输入框里按住 Control 说话，它会实时识别、整理、翻译或润色，然后自动写回当前应用。",
                highlights: [
                    "适合写消息、邮件、笔记、需求、英文回复和中英混合输入。",
                    "默认使用自动模式，让应用判断是普通听写、分点整理还是润色。",
                    "原始录音不会保存，历史记录默认关闭。"
                ]
            ),
            WelcomeStepCopy(
                sidebarTitle: "基本使用",
                sidebarSubtitle: "按住 Control，说完松开。",
                title: "三个动作，就能开始输入。",
                lead: "先把光标放进你想输入的位置。按住 Control 开始说话，松开后等待几秒，整理好的文字会自动出现在当前输入框。",
                highlights: [
                    "说话时会显示浮动窗口，让你看到识别中的内容。",
                    "如果没有识别到声音，窗口会提示并自动关闭。",
                    "想取消时，可以从菜单栏选择取消听写。"
                ]
            ),
            WelcomeStepCopy(
                sidebarTitle: "选择模式",
                sidebarSubtitle: "听写、翻译、润色都在这里。",
                title: "按场景选择处理方式。",
                lead: "不同模式决定松开 Control 后文字会怎样被处理。大多数时候用自动模式就够了，需要明确翻译或润色时再切换模式。",
                highlights: [
                    "自动模式会判断口语整理、列表、正式消息、英文纠错或轻量翻译。",
                    "翻译模式会按设置里的目标语言输出译文。",
                    "问选中内容可以对选中文字提出修改、总结或解释请求。"
                ]
            ),
            WelcomeStepCopy(
                sidebarTitle: "完成配置",
                sidebarSubtitle: "API Key 和系统权限。",
                title: "配置完成后，才能稳定使用。",
                lead: "首次使用需要准备两个 API Key，并允许 macOS 麦克风和辅助功能权限。配置完成后，快捷键监听和自动粘贴才会可靠工作。",
                highlights: [
                    "语音识别 API Key 负责把你说的话实时转成文字。",
                    "文字 AI API Key 负责整理、翻译、润色和处理选中文字。",
                    "辅助功能权限用于监听 Control 长按，以及把结果写入当前输入框。"
                ]
            )
        ]
    )

    private static let english = WelcomeLocalizedCopy(
        titlebar: "SpeakMore Onboarding",
        brandTagline: "Use your voice to finish writing.",
        sidebarNote: "This page appears automatically after first install. You can reopen it later from the menu bar.",
        languageLabel: "Interface language",
        progressLabel: "Tutorial progress",
        skipButtonTitle: "Later",
        previousButtonTitle: "Back",
        nextButtonTitle: "Next",
        startSetupButtonTitle: "Start setup",
        overviewHeaderLeft: "Current app",
        overviewHeaderRight: "Ready",
        overviewCursor: "Cursor is here, ready for input...",
        overviewOutput: "I can join the meeting tomorrow afternoon. We can confirm the goal first, then discuss the technical plan.",
        usageHeaderLeft: "After holding",
        usageHeaderRight: "Listening",
        usageSteps: [
            ("Place cursor", "Any chat, email, or document field."),
            ("Hold to speak", "Release when you finish."),
            ("Auto write", "Recognized text is cleaned up and inserted.")
        ],
        modes: [
            ("Auto", "Automatically chooses the best output style."),
            ("Dictate", "Lightly cleans speech while preserving meaning."),
            ("Translate", "Translates into your target language."),
            ("Polish", "Turns rough speech into sendable text."),
            ("Ask Selection", "Summarize, explain, rewrite, or translate selected text.")
        ],
        configRows: [
            ("Speech API Key", "Used for real-time transcription.", "Configure"),
            ("Text AI API Key", "Used for cleanup, translation, and polishing.", "Configure"),
            ("Microphone Permission", "Allows the app to hear your voice.", "System prompt"),
            ("Accessibility Permission", "Used for hotkeys and automatic paste.", "System Settings")
        ],
        configNote: "We include a free trial with 2,000 output characters and 10 minutes of speech recognition. After that, enter your own API key to continue.",
        steps: [
            WelcomeStepCopy(
                sidebarTitle: "What it does",
                sidebarSubtitle: "Turn speech into ready-to-send text.",
                title: "Turn spoken words into text you can send.",
                lead: "SpeakMore is a macOS menu bar voice input tool. Hold Control in any text field to speak, and it can transcribe, clean up, translate, or polish your words before writing them back to the current app.",
                highlights: [
                    "Useful for messages, email, notes, specs, English replies, and mixed Chinese-English input.",
                    "Auto mode decides whether to dictate, structure, polish, or lightly translate.",
                    "Original recordings are not saved, and history is off by default."
                ]
            ),
            WelcomeStepCopy(
                sidebarTitle: "Basic use",
                sidebarSubtitle: "Hold Control, speak, then release.",
                title: "Start typing with three simple actions.",
                lead: "Put the cursor where you want text to appear. Hold Control while speaking, then release it. After a short wait, the cleaned-up text appears in the current input field.",
                highlights: [
                    "A small floating window shows the recognized speech while you talk.",
                    "If no speech is detected, the window shows a hint and closes automatically.",
                    "You can cancel dictation from the menu bar."
                ]
            ),
            WelcomeStepCopy(
                sidebarTitle: "Choose a mode",
                sidebarSubtitle: "Dictate, translate, polish, and more.",
                title: "Choose how text should be handled.",
                lead: "The mode decides what happens after you release Control. Auto mode is enough most of the time; switch modes when you explicitly need translation or polishing.",
                highlights: [
                    "Auto mode can detect cleanup, lists, formal messages, English correction, or light translation.",
                    "Translate mode outputs text in your configured target language.",
                    "Ask Selection lets you summarize, explain, rewrite, or translate selected text."
                ]
            ),
            WelcomeStepCopy(
                sidebarTitle: "Finish setup",
                sidebarSubtitle: "API keys and system permissions.",
                title: "Finish setup for reliable use.",
                lead: "First use requires two API keys plus macOS microphone and accessibility permissions. Once configured, hotkey listening and automatic paste can work reliably.",
                highlights: [
                    "The speech recognition API key turns your voice into text.",
                    "The text AI API key handles cleanup, translation, polishing, and selected text actions.",
                    "Accessibility permission is used for Control hold detection and writing results into the current input field."
                ]
            )
        ]
    )
}

private struct WelcomeStepCopy {
    let sidebarTitle: String
    let sidebarSubtitle: String
    let title: String
    let lead: String
    let highlights: [String]
}

#Preview {
    WelcomeOnboardingView {}
        .frame(width: 1080, height: 720)
}
