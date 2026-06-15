import AppKit
import ApplicationServices

@MainActor
protocol SelectedTextReading {
    func readSelectedText() async -> String?
}

@MainActor
final class SelectedTextReader: SelectedTextReading {
    typealias AccessibilityReader = @MainActor () -> String?
    typealias ClipboardFallbackReader = @MainActor () async -> String?

    private let accessibilityReader: AccessibilityReader
    private let clipboardFallbackReader: ClipboardFallbackReader

    init(
        accessibilityReader: @escaping AccessibilityReader = SelectedTextReader.readAccessibilitySelectedText,
        clipboardFallbackReader: @escaping ClipboardFallbackReader = {
            await ClipboardSelectedTextReader().readSelectedText()
        }
    ) {
        self.accessibilityReader = accessibilityReader
        self.clipboardFallbackReader = clipboardFallbackReader
    }

    func readSelectedText() async -> String? {
        if let selectedText = Self.normalizedText(accessibilityReader()) {
            return selectedText
        }

        return Self.normalizedText(await clipboardFallbackReader())
    }

    static func normalizedText(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func readAccessibilitySelectedText() -> String? {
        guard AXIsProcessTrusted(),
              let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let applicationElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        guard let focusedElement = copyAttribute(kAXFocusedUIElementAttribute as CFString, from: applicationElement),
              CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return nil
        }

        return readSelectedText(from: focusedElement as! AXUIElement)
    }

    private static func readSelectedText(from element: AXUIElement) -> String? {
        if let selectedText = copyAttribute(kAXSelectedTextAttribute as CFString, from: element) as? String,
           let normalized = normalizedText(selectedText) {
            return normalized
        }

        guard let selectedRangeValue = copyAttribute(kAXSelectedTextRangeAttribute as CFString, from: element),
              CFGetTypeID(selectedRangeValue) == AXValueGetTypeID() else {
            return nil
        }

        let selectedRange = selectedRangeValue as! AXValue
        guard AXValueGetType(selectedRange) == .cfRange else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(selectedRange, .cfRange, &range),
              range.length > 0 else {
            return nil
        }

        var rangedText: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            selectedRange,
            &rangedText
        )
        guard result == .success else {
            return nil
        }

        return normalizedText(rangedText as? String)
    }

    private static func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value
    }
}

@MainActor
final class ClipboardSelectedTextReader {
    typealias CopyShortcutPoster = @MainActor () throws -> Void
    typealias AccessibilityPermissionChecker = @MainActor () -> Bool
    typealias AccessibilityPermissionPrompter = @MainActor () -> Void
    typealias ClipboardUpdateWaiter = @MainActor () async -> Void

    private let clipboard: ClipboardController
    private let copyShortcutPoster: CopyShortcutPoster
    private let accessibilityPermissionChecker: AccessibilityPermissionChecker
    private let accessibilityPermissionPrompter: AccessibilityPermissionPrompter
    private let waitForClipboardUpdate: ClipboardUpdateWaiter

    init(
        clipboard: ClipboardController = ClipboardController(),
        copyShortcutPoster: @escaping CopyShortcutPoster = ClipboardSelectedTextReader.postCommandC,
        accessibilityPermissionChecker: @escaping AccessibilityPermissionChecker = { AXIsProcessTrusted() },
        accessibilityPermissionPrompter: @escaping AccessibilityPermissionPrompter = ClipboardSelectedTextReader.promptForAccessibilityPermission,
        waitForClipboardUpdate: @escaping ClipboardUpdateWaiter = {
            try? await Task.sleep(nanoseconds: 80_000_000)
        }
    ) {
        self.clipboard = clipboard
        self.copyShortcutPoster = copyShortcutPoster
        self.accessibilityPermissionChecker = accessibilityPermissionChecker
        self.accessibilityPermissionPrompter = accessibilityPermissionPrompter
        self.waitForClipboardUpdate = waitForClipboardUpdate
    }

    func readSelectedText() async -> String? {
        guard accessibilityPermissionChecker() else {
            accessibilityPermissionPrompter()
            return nil
        }

        let snapshot = clipboard.snapshot()
        let originalChangeCount = clipboard.changeCount

        do {
            try copyShortcutPoster()
        } catch {
            return nil
        }

        await waitForClipboardUpdate()

        let copiedChangeCount = clipboard.changeCount
        let copiedText = copiedChangeCount != originalChangeCount ? clipboard.string() : nil
        clipboard.restore(snapshot, ifChangeCountIs: copiedChangeCount)

        return SelectedTextReader.normalizedText(copiedText)
    }

    private static func postCommandC() throws {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) else {
            throw SelectedTextReaderError.keyboardEventCreationFailed
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private static func promptForAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

enum SelectedTextReaderError: LocalizedError, Equatable {
    case keyboardEventCreationFailed

    var errorDescription: String? {
        switch self {
        case .keyboardEventCreationFailed:
            "\(AppBrand.englishName) 没能创建复制快捷键事件。"
        }
    }
}
