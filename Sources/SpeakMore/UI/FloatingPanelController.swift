import AppKit
import Combine
import SwiftUI

@MainActor
protocol FloatingPanelControlling: AnyObject {
    func show()
    func hide()
}

@MainActor
final class FloatingPanelController: NSObject, NSWindowDelegate, FloatingPanelControlling {
    private let panel: NSPanel
    private let shadowPanel: NSPanel
    private let shadowView: FloatingPanelShadowView
    private let state: AppState
    private let onCancel: () -> Void
    private let onOpenSettings: () -> Void
    private var cancellables: Set<AnyCancellable> = []

    init(
        state: AppState,
        onCancel: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void = {}
    ) {
        self.state = state
        self.onCancel = onCancel
        self.onOpenSettings = onOpenSettings
        let contentView = NSHostingView(
            rootView: FloatingWindowView(
                state: state,
                onCancel: onCancel,
                onOpenSettings: onOpenSettings
            )
        )
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor

        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: FloatingWindowPresentation.initialPanelSize.width,
                height: FloatingWindowPresentation.initialPanelSize.height
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let shadowSize = CGSize(
            width: FloatingWindowPresentation.initialPanelSize.width + FloatingWindowPresentation.shadowOutset * 2,
            height: FloatingWindowPresentation.initialPanelSize.height + FloatingWindowPresentation.shadowOutset * 2
        )
        let shadowPanel = NSPanel(
            contentRect: NSRect(origin: .zero, size: shadowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let shadowView = FloatingPanelShadowView()
        self.panel = panel
        self.shadowPanel = shadowPanel
        self.shadowView = shadowView
        super.init()

        panel.contentView = contentView
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.center()

        shadowPanel.contentView = shadowView
        shadowPanel.isReleasedWhenClosed = false
        shadowPanel.level = panel.level
        shadowPanel.backgroundColor = .clear
        shadowPanel.isOpaque = false
        shadowPanel.hasShadow = false
        shadowPanel.ignoresMouseEvents = true
        shadowPanel.collectionBehavior = panel.collectionBehavior

        state.$status.sink { [weak self] status in
            if status == .idle {
                self?.hide()
            }
        }
        .store(in: &cancellables)

        Publishers.MergeMany(
            state.$status.map { _ in () }.eraseToAnyPublisher(),
            state.$mode.map { _ in () }.eraseToAnyPublisher(),
            state.$rawTranscript.map { _ in () }.eraseToAnyPublisher(),
            state.$finalText.map { _ in () }.eraseToAnyPublisher(),
            state.$errorMessage.map { _ in () }.eraseToAnyPublisher(),
            state.$audioQualitySnapshot.map { _ in () }.eraseToAnyPublisher(),
            state.$interfaceLanguage.map { _ in () }.eraseToAnyPublisher()
        )
        .sink { [weak self] _ in
            self?.applyPreferredPanelSize(preservingCenter: true)
        }
        .store(in: &cancellables)
    }

    func show() {
        applyPreferredPanelSize(preservingCenter: false)
        panel.contentView?.layoutSubtreeIfNeeded()
        panel.center()
        positionShadowPanel()
        shadowPanel.orderFrontRegardless()
        panel.orderFrontRegardless()
    }

    func hide() {
        shadowPanel.orderOut(nil)
        panel.orderOut(nil)
    }

    func windowDidMove(_ notification: Notification) {
        positionShadowPanel()
    }

    func windowDidResize(_ notification: Notification) {
        positionShadowPanel()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        onCancel()
        hide()
        return false
    }

    private func applyPreferredPanelSize(preservingCenter: Bool) {
        let presentation = FloatingWindowPresentation(state: state, language: state.interfaceLanguage)
        let size = sizeThatFitsVisibleScreen(
            CGSize(
                width: FloatingWindowPresentation.panelWidth,
                height: presentation.visibleCardHeight
            )
        )
        guard panel.frame.size != size else {
            positionShadowPanel()
            return
        }

        let previousCenter = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        panel.setContentSize(size)

        if preservingCenter && panel.isVisible {
            panel.setFrameOrigin(
                NSPoint(
                    x: previousCenter.x - size.width / 2,
                    y: previousCenter.y - size.height / 2
                )
            )
        }
        positionShadowPanel()
    }

    private func sizeThatFitsVisibleScreen(_ size: CGSize) -> CGSize {
        guard let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame else {
            return size
        }

        let maximumHeight = max(
            FloatingWindowPresentation.minimumPanelHeight,
            min(FloatingWindowPresentation.maximumPanelHeight, visibleFrame.height - 80)
        )
        return CGSize(width: size.width, height: min(size.height, maximumHeight))
    }

    private func positionShadowPanel() {
        let outset = FloatingWindowPresentation.shadowOutset
        let panelFrame = panel.frame
        let shadowFrame = NSRect(
            x: panelFrame.minX - outset,
            y: panelFrame.minY - outset,
            width: panelFrame.width + outset * 2,
            height: panelFrame.height + outset * 2
        )
        shadowView.update(cardSize: panelFrame.size, shadowOutset: outset)
        shadowPanel.setFrame(shadowFrame, display: true)
    }
}

private final class FloatingPanelShadowView: NSView {
    private let shadowLayer = CALayer()
    private var cardSize = FloatingWindowPresentation.initialPanelSize
    private var shadowOutset = FloatingWindowPresentation.shadowOutset

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
        shadowLayer.masksToBounds = false
        layer?.addSublayer(shadowLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(cardSize: CGSize, shadowOutset: CGFloat) {
        self.cardSize = cardSize
        self.shadowOutset = shadowOutset
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    override func layout() {
        super.layout()

        let cardRect = CGRect(
            x: shadowOutset,
            y: shadowOutset,
            width: cardSize.width,
            height: cardSize.height
        )
        shadowLayer.frame = cardRect
        shadowLayer.cornerRadius = FloatingWindowPresentation.cornerRadius
        shadowLayer.backgroundColor = NSColor.textBackgroundColor.cgColor
        shadowLayer.shadowColor = NSColor.black.cgColor
        shadowLayer.shadowOpacity = FloatingWindowPresentation.shadowOpacity
        shadowLayer.shadowRadius = FloatingWindowPresentation.shadowRadius
        shadowLayer.shadowOffset = CGSize(width: 0, height: FloatingWindowPresentation.shadowYOffset)
        shadowLayer.shadowPath = CGPath(
            roundedRect: CGRect(origin: .zero, size: cardSize),
            cornerWidth: FloatingWindowPresentation.cornerRadius,
            cornerHeight: FloatingWindowPresentation.cornerRadius,
            transform: nil
        )
        shadowLayer.shouldRasterize = true
        shadowLayer.rasterizationScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
    }
}
