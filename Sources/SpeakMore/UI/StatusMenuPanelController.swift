import AppKit
import SwiftUI

@MainActor
final class StatusMenuPanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private weak var anchorWindow: NSWindow?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var isAuxiliaryInteractionActive = false

    init(
        state: AppState,
        startDefault: @escaping @MainActor () -> Void,
        startMode: @escaping @MainActor (SpeakMoreMode) -> Void,
        openSettings: @escaping @MainActor () -> Void,
        changeLanguage: @escaping @MainActor (AppLanguage) -> Void,
        quit: @escaping @MainActor () -> Void
    ) {
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: StatusMenuPanelView.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        let contentView = NSHostingView(
            rootView: StatusMenuPanelView(
                state: state,
                startDefault: { [weak self] in
                    self?.hide()
                    startDefault()
                },
                startMode: { [weak self] mode in
                    self?.hide()
                    startMode(mode)
                },
                openSettings: { [weak self] in
                    self?.hide()
                    openSettings()
                },
                changeLanguage: { language in
                    changeLanguage(language)
                },
                setAuxiliaryInteractionActive: { [weak self] isActive in
                    self?.isAuxiliaryInteractionActive = isActive
                },
                quit: { [weak self] in
                    self?.hide()
                    quit()
                }
            )
        )
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        panel.contentView = contentView
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.titleVisibility = .hidden
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if panel.isVisible {
            hide()
        } else {
            show(relativeTo: button)
        }
    }

    func hide() {
        isAuxiliaryInteractionActive = false
        panel.orderOut(nil)
        removeEventMonitors()
    }

    private func show(relativeTo button: NSStatusBarButton) {
        let size = StatusMenuPanelView.panelSize
        panel.setContentSize(size)

        guard let window = button.window else {
            anchorWindow = nil
            panel.center()
            panel.orderFrontRegardless()
            installEventMonitors()
            return
        }

        anchorWindow = window
        let buttonRectInWindow = button.convert(button.bounds, to: nil)
        let buttonRectOnScreen = window.convertToScreen(buttonRectInWindow)
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        panel.setFrameOrigin(
            StatusMenuPanelLayout.origin(
                panelSize: size,
                buttonRectOnScreen: buttonRectOnScreen,
                visibleFrame: visibleFrame
            )
        )
        panel.orderFrontRegardless()
        installEventMonitors()
    }

    private func installEventMonitors() {
        removeEventMonitors()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            if StatusMenuPanelEventRouting.shouldHidePanel(
                isPanelVisible: self.panel.isVisible,
                panelWindow: self.panel,
                anchorWindow: self.anchorWindow,
                eventWindow: event.window,
                isAuxiliaryInteractionActive: self.isAuxiliaryInteractionActive
            ) {
                self.hide()
            }
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.hide()
            }
        }
    }

    private func removeEventMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }
}

enum StatusMenuPanelEventRouting {
    static func shouldHidePanel(
        isPanelVisible: Bool,
        panelWindow: NSWindow,
        anchorWindow: NSWindow?,
        eventWindow: NSWindow?,
        isAuxiliaryInteractionActive: Bool
    ) -> Bool {
        guard isPanelVisible else { return false }
        guard !isAuxiliaryInteractionActive else { return false }
        return eventWindow !== panelWindow && eventWindow !== anchorWindow
    }
}

enum StatusMenuPanelLayout {
    static let screenEdgeMargin: CGFloat = 8

    static func origin(
        panelSize: CGSize,
        buttonRectOnScreen: NSRect,
        visibleFrame: NSRect
    ) -> NSPoint {
        let preferredX = buttonRectOnScreen.midX - panelSize.width / 2
        let x = min(
            max(preferredX, visibleFrame.minX + screenEdgeMargin),
            visibleFrame.maxX - panelSize.width - screenEdgeMargin
        )
        let y = max(visibleFrame.minY + screenEdgeMargin, buttonRectOnScreen.minY - panelSize.height)

        return NSPoint(x: x, y: y)
    }
}

struct StatusMenuPanelView: View {
    static let cardTopInset: CGFloat = 0
    static let horizontalShadowOutset: CGFloat = 28
    static let bottomShadowOutset: CGFloat = 28
    static let cardWidth: CGFloat = 286
    static let cardHeight: CGFloat = 390
    static let rowHorizontalPadding: CGFloat = 14
    static let iconColumnWidth: CGFloat = 22
    static let rowHeight: CGFloat = 30
    static let rowSpacing: CGFloat = 5
    static let estimatedContentHeight: CGFloat = statusHeaderHeight
        + sectionLabelHeight
        + dividerHeight * 2
        + rowHeight * menuRowCount
        + rowSpacing * (cardChildCount - 1)
    static let panelSize = CGSize(
        width: cardWidth + horizontalShadowOutset * 2,
        height: cardTopInset + cardHeight + bottomShadowOutset
    )
    private static let statusHeaderHeight: CGFloat = 30
    private static let sectionLabelHeight: CGFloat = 19
    private static let dividerHeight: CGFloat = 1
    private static let menuRowCount: CGFloat = 9
    private static let cardChildCount: CGFloat = 11

    @ObservedObject var state: AppState
    let startDefault: @MainActor () -> Void
    let startMode: @MainActor (SpeakMoreMode) -> Void
    let openSettings: @MainActor () -> Void
    @State private var selectedInterfaceLanguage: AppLanguage
    @State private var isLanguagePickerPresented = false
    let changeLanguage: @MainActor (AppLanguage) -> Void
    let setAuxiliaryInteractionActive: @MainActor (Bool) -> Void
    let quit: @MainActor () -> Void

    init(
        state: AppState,
        startDefault: @escaping @MainActor () -> Void,
        startMode: @escaping @MainActor (SpeakMoreMode) -> Void,
        openSettings: @escaping @MainActor () -> Void,
        changeLanguage: @escaping @MainActor (AppLanguage) -> Void,
        setAuxiliaryInteractionActive: @escaping @MainActor (Bool) -> Void,
        quit: @escaping @MainActor () -> Void
    ) {
        self.state = state
        self.startDefault = startDefault
        self.startMode = startMode
        self.openSettings = openSettings
        self.changeLanguage = changeLanguage
        self.setAuxiliaryInteractionActive = setAuxiliaryInteractionActive
        self.quit = quit
        _selectedInterfaceLanguage = State(initialValue: state.interfaceLanguage)
    }

    private var interfaceLanguage: AppLanguage {
        selectedInterfaceLanguage
    }

    private var strings: AppInterfaceStrings {
        AppInterfaceStrings(language: interfaceLanguage)
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.14))
                .frame(width: Self.cardWidth, height: Self.cardHeight)
                .blur(radius: 16)
                .offset(y: 8)

            card
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
        .background(Color.clear)
        .onReceive(state.$interfaceLanguage) { language in
            selectedInterfaceLanguage = language
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Self.rowSpacing) {
            Text(MenuBarStatusPresentation(status: state.status, mode: state.mode, language: interfaceLanguage).menuStatusTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 14)

            Divider()
                .padding(.horizontal, 14)

            menuButton(strings.startVoiceInput, systemImage: "waveform", action: startDefault)

            Text(strings.chooseModeAndStart)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 2)

            ForEach(SpeakMoreMode.allCases, id: \.self) { mode in
                menuButton(
                    strings.modeTitle(mode),
                    systemImage: modeIcon(for: mode),
                    checked: state.mode == mode
                ) {
                    startMode(mode)
                }
            }

            Divider()
                .padding(.horizontal, 14)

            menuButton(strings.settingsAndAPI, systemImage: "gearshape", action: openSettings)
            languageMenu
            menuButton(strings.quitSpeakMore, systemImage: "power", action: quit)
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var languageMenu: some View {
        Button {
            isLanguagePickerPresented.toggle()
            setAuxiliaryInteractionActive(isLanguagePickerPresented)
        } label: {
            HStack(spacing: 10) {
                menuIcon("globe")
                Text(strings.interfaceLanguage)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(strings.languageTitle(interfaceLanguage))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, Self.rowHorizontalPadding)
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isLanguagePickerPresented, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        selectedInterfaceLanguage = language
                        changeLanguage(language)
                        isLanguagePickerPresented = false
                        setAuxiliaryInteractionActive(false)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .opacity(language == interfaceLanguage ? 1 : 0)
                                .frame(width: 16)
                            Text(strings.languageTitle(language))
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .frame(width: 180, height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .onChange(of: isLanguagePickerPresented) { _, isPresented in
            setAuxiliaryInteractionActive(isPresented)
        }
        .onDisappear {
            setAuxiliaryInteractionActive(false)
        }
    }

    private func menuButton(
        _ title: String,
        systemImage: String,
        checked: Bool = false,
        disabled: Bool = false,
        action: @escaping @MainActor () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                menuIcon(checked ? "checkmark" : systemImage)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                Spacer()
            }
            .foregroundStyle(.primary)
            .opacity(disabled ? 0.45 : 1)
            .padding(.horizontal, Self.rowHorizontalPadding)
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func menuIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: Self.iconColumnWidth, height: 18, alignment: .center)
    }

    private func modeIcon(for mode: SpeakMoreMode) -> String {
        switch mode {
        case .auto:
            "sparkles"
        case .dictate:
            "text.cursor"
        case .translate:
            "globe"
        case .polish:
            "wand.and.sparkles"
        case .askSelectedText:
            "selection.pin.in.out"
        }
    }
}
