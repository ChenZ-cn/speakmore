import AppKit
import SwiftUI

@MainActor
final class WelcomeOnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: @MainActor () -> Void
    private var didClose = false

    init(onClose: @escaping @MainActor () -> Void) {
        self.onClose = onClose

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 716),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppBrand.englishName) Welcome"
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 1080, height: 716)
        window.contentMaxSize = NSSize(width: 1080, height: 716)
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        super.init(window: window)

        window.delegate = self
        window.center()
        window.contentViewController = NSHostingController(
            rootView: WelcomeOnboardingView { [weak self] in
                self?.window?.close()
            }
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func windowWillClose(_ notification: Notification) {
        guard !didClose else { return }
        didClose = true
        onClose()
    }
}
