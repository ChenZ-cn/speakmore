import AppKit
import Foundation

enum HotKeyRegistrationError: Error, LocalizedError {
    case eventMonitorInstallFailed

    var errorDescription: String? {
        switch self {
        case .eventMonitorInstallFailed:
            "Failed to install Control hold event monitor."
        }
    }
}

final class HotKeyController: NSObject {
    static let defaultLongPressDelay: TimeInterval = 0.5

    private static let relevantModifierFlags: NSEvent.ModifierFlags = [
        .control,
        .shift,
        .option,
        .command,
        .function
    ]

    private let longPressDelay: TimeInterval
    private let onPressed: () -> Void
    private let onReleased: () -> Void
    private let onModeShortcut: (SpeakMoreMode) -> Void
    private var recognizer: VoiceInputShortcutRecognizer
    private var startTimer: Timer?
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(
        shortcut: VoiceInputShortcut = .default,
        longPressDelay: TimeInterval = HotKeyController.defaultLongPressDelay,
        onPressed: @escaping () -> Void,
        onReleased: @escaping () -> Void,
        onModeShortcut: @escaping (SpeakMoreMode) -> Void = { _ in }
    ) {
        self.longPressDelay = longPressDelay
        self.onPressed = onPressed
        self.onReleased = onReleased
        self.onModeShortcut = onModeShortcut
        self.recognizer = VoiceInputShortcutRecognizer(shortcut: shortcut)
        super.init()
    }

    func registerDefaultHotKey() throws {
        guard localMonitor == nil, globalMonitor == nil else {
            return
        }

        let eventMask: NSEvent.EventTypeMask = [.flagsChanged, .keyDown, .keyUp]
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handle(event)
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handle(event)
        }

        guard localMonitor != nil || globalMonitor != nil else {
            throw HotKeyRegistrationError.eventMonitorInstallFailed
        }
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            perform(
                recognizer.handle(
                    .flagsChanged(ShortcutModifiers(eventModifierFlags: event.modifierFlags))
                )
            )
        case .keyDown:
            perform(
                recognizer.handle(
                    .keyDown(
                        keyCode: event.keyCode,
                        charactersIgnoringModifiers: event.charactersIgnoringModifiers,
                        modifiers: ShortcutModifiers(eventModifierFlags: event.modifierFlags),
                        isRepeat: event.isARepeat
                    ),
                    modeShortcut: Self.modeShortcut(for: event)
                )
            )
        case .keyUp:
            perform(
                recognizer.handle(
                    .keyUp(
                        keyCode: event.keyCode,
                        modifiers: ShortcutModifiers(eventModifierFlags: event.modifierFlags)
                    )
                )
            )
        default:
            break
        }
    }

    private func perform(_ actions: [ControlHoldGestureAction]) {
        for action in actions {
            switch action {
            case .scheduleStart:
                startTimer?.invalidate()
                startTimer = Timer.scheduledTimer(
                    timeInterval: longPressDelay,
                    target: self,
                    selector: #selector(startTimerFired(_:)),
                    userInfo: nil,
                    repeats: false
                )
            case .cancelScheduledStart:
                startTimer?.invalidate()
                startTimer = nil
            case .start:
                startTimer?.invalidate()
                startTimer = nil
                onPressed()
            case .finish:
                startTimer?.invalidate()
                startTimer = nil
                onReleased()
            case let .switchMode(mode):
                onModeShortcut(mode)
            }
        }
    }

    private static func modeShortcut(for event: NSEvent) -> SpeakMoreMode? {
        modeShortcut(
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            keyCode: event.keyCode,
            modifierFlags: event.modifierFlags
        )
    }

    static func modeShortcut(
        charactersIgnoringModifiers: String?,
        keyCode: UInt16,
        modifierFlags: NSEvent.ModifierFlags
    ) -> SpeakMoreMode? {
        let modifierFlags = modifierFlags.intersection(relevantModifierFlags)
        guard modifierFlags == .control else {
            return nil
        }

        switch charactersIgnoringModifiers {
        case "1":
            return .auto
        case "2":
            return .dictate
        case "3":
            return .translate
        case "4":
            return .polish
        case "5":
            return .askSelectedText
        default:
            break
        }

        switch keyCode {
        case 18, 83:
            return .auto
        case 19, 84:
            return .dictate
        case 20, 85:
            return .translate
        case 21, 86:
            return .polish
        case 23, 87:
            return .askSelectedText
        default:
            return nil
        }
    }

    @objc private func startTimerFired(_ timer: Timer) {
        startTimer?.invalidate()
        startTimer = nil
        perform(recognizer.longPressDelayElapsed())
    }

    deinit {
        startTimer?.invalidate()
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
    }
}
