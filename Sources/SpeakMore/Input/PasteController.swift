import AppKit
import ApplicationServices

@MainActor
protocol PasteTextSink {
    func paste(text: String) throws
    func revertLastPastedText() throws -> Bool
    func revertLastPastedSentence() throws -> Bool
}

@MainActor
final class PasteController: PasteTextSink {
    typealias KeyboardShortcutPoster = @MainActor () throws -> Void
    typealias AccessibilityPermissionChecker = @MainActor () -> Bool
    typealias AccessibilityPermissionPrompter = @MainActor () -> Void
    typealias LastInsertionReverter = @MainActor (String) throws -> Bool
    typealias RestoreScheduler = @MainActor (DispatchWorkItem) -> Void

    private let clipboard: ClipboardController
    private let keyboardShortcutPoster: KeyboardShortcutPoster
    private let accessibilityPermissionChecker: AccessibilityPermissionChecker
    private let accessibilityPermissionPrompter: AccessibilityPermissionPrompter
    private let lastInsertionReverter: LastInsertionReverter
    private let restoreScheduler: RestoreScheduler
    private var pendingRestore: DispatchWorkItem?
    private var activeOriginalSnapshot: ClipboardSnapshot?
    private var lastPastedText: String?

    init(
        clipboard: ClipboardController = ClipboardController(),
        keyboardShortcutPoster: @escaping KeyboardShortcutPoster = PasteController.postCommandV,
        accessibilityPermissionChecker: @escaping AccessibilityPermissionChecker = { AXIsProcessTrusted() },
        accessibilityPermissionPrompter: @escaping AccessibilityPermissionPrompter = PasteController.promptForAccessibilityPermission,
        lastInsertionReverter: @escaping LastInsertionReverter = { text in
            try FocusedTextInsertionReverter().revertLastInsertion(text)
        },
        restoreScheduler: @escaping RestoreScheduler = { workItem in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    ) {
        self.clipboard = clipboard
        self.keyboardShortcutPoster = keyboardShortcutPoster
        self.accessibilityPermissionChecker = accessibilityPermissionChecker
        self.accessibilityPermissionPrompter = accessibilityPermissionPrompter
        self.lastInsertionReverter = lastInsertionReverter
        self.restoreScheduler = restoreScheduler
    }

    func paste(text: String) throws {
        guard accessibilityPermissionChecker() else {
            accessibilityPermissionPrompter()
            throw PasteError.accessibilityPermissionMissing
        }

        let snapshot = activeOriginalSnapshot ?? clipboard.snapshot()
        activeOriginalSnapshot = snapshot
        let stagedChangeCount = clipboard.writeTextReturningChangeCount(text)

        try keyboardShortcutPoster()
        lastPastedText = text

        pendingRestore?.cancel()
        let restore = DispatchWorkItem { [weak self, clipboard] in
            clipboard.restore(snapshot, ifChangeCountIs: stagedChangeCount)
            self?.activeOriginalSnapshot = nil
            self?.pendingRestore = nil
        }
        pendingRestore = restore
        restoreScheduler(restore)
    }

    func revertLastPastedText() throws -> Bool {
        guard let lastPastedText,
              !lastPastedText.isEmpty else {
            return false
        }

        let didRevert = try lastInsertionReverter(lastPastedText)
        if didRevert {
            self.lastPastedText = nil
        }
        return didRevert
    }

    func revertLastPastedSentence() throws -> Bool {
        guard let lastPastedText,
              let split = Self.trailingSentence(in: lastPastedText) else {
            return false
        }

        let didRevert = try lastInsertionReverter(split.sentence)
        if didRevert {
            self.lastPastedText = split.remaining.isEmpty ? nil : split.remaining
        }
        return didRevert
    }

    private static func trailingSentence(in text: String) -> (remaining: String, sentence: String)? {
        guard !text.isEmpty else {
            return nil
        }

        let contentEnd = text.lastIndex { !$0.isWhitespace } ?? text.endIndex
        let suffixEnd = contentEnd == text.endIndex ? text.endIndex : text.index(after: contentEnd)
        guard suffixEnd > text.startIndex else {
            return nil
        }

        let content = text[..<suffixEnd]
        let lastContentIndex = content.index(before: content.endIndex)
        let searchEnd = sentenceEnders.contains(content[lastContentIndex])
            ? lastContentIndex
            : content.endIndex

        var sentenceStart = text.startIndex
        var current = text.startIndex
        while current < searchEnd {
            if sentenceEnders.contains(text[current]) {
                sentenceStart = text.index(after: current)
            }
            current = text.index(after: current)
        }

        let sentence = String(text[sentenceStart...])
        let remaining = String(text[..<sentenceStart])
        guard !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return (remaining, sentence)
    }

    private static let sentenceEnders = Set<Character>(["。", "！", "？", ".", "!", "?", "\n"])

    private static func postCommandV() throws {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            throw PasteError.keyboardEventCreationFailed
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    fileprivate static func promptForAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

@MainActor
final class FocusedTextInsertionReverter {
    typealias AccessibilityPermissionChecker = @MainActor () -> Bool
    typealias AccessibilityPermissionPrompter = @MainActor () -> Void
    typealias DeleteKeyPoster = @MainActor () throws -> Void

    private let accessibilityPermissionChecker: AccessibilityPermissionChecker
    private let accessibilityPermissionPrompter: AccessibilityPermissionPrompter
    private let deleteKeyPoster: DeleteKeyPoster

    init(
        accessibilityPermissionChecker: @escaping AccessibilityPermissionChecker = { AXIsProcessTrusted() },
        accessibilityPermissionPrompter: @escaping AccessibilityPermissionPrompter = PasteController.promptForAccessibilityPermission,
        deleteKeyPoster: @escaping DeleteKeyPoster = FocusedTextInsertionReverter.postDeleteKey
    ) {
        self.accessibilityPermissionChecker = accessibilityPermissionChecker
        self.accessibilityPermissionPrompter = accessibilityPermissionPrompter
        self.deleteKeyPoster = deleteKeyPoster
    }

    func revertLastInsertion(_ insertedText: String) throws -> Bool {
        guard accessibilityPermissionChecker() else {
            accessibilityPermissionPrompter()
            throw PasteError.accessibilityPermissionMissing
        }

        guard let focusedElement = Self.focusedElement(),
              let currentValue = Self.copyAttribute(kAXValueAttribute as CFString, from: focusedElement) as? String,
              let selectedRange = Self.selectedTextRange(from: focusedElement),
              selectedRange.length == 0 else {
            return false
        }

        let currentNSString = currentValue as NSString
        let insertedNSString = insertedText as NSString
        let insertedLength = insertedNSString.length
        guard insertedLength > 0,
              selectedRange.location >= insertedLength,
              selectedRange.location <= currentNSString.length else {
            return false
        }

        let candidateRange = NSRange(
            location: selectedRange.location - insertedLength,
            length: insertedLength
        )
        guard currentNSString.substring(with: candidateRange) == insertedText else {
            return false
        }

        var deletionRange = CFRange(location: candidateRange.location, length: candidateRange.length)
        guard let deletionRangeValue = AXValueCreate(.cfRange, &deletionRange),
              AXUIElementSetAttributeValue(
                focusedElement,
                kAXSelectedTextRangeAttribute as CFString,
                deletionRangeValue
              ) == .success else {
            return false
        }

        try deleteKeyPoster()
        return true
    }

    private static func focusedElement() -> AXUIElement? {
        guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let applicationElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        guard let focusedElement = copyAttribute(kAXFocusedUIElementAttribute as CFString, from: applicationElement),
              CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return nil
        }

        return (focusedElement as! AXUIElement)
    }

    private static func selectedTextRange(from element: AXUIElement) -> CFRange? {
        guard let selectedRangeValue = copyAttribute(kAXSelectedTextRangeAttribute as CFString, from: element),
              CFGetTypeID(selectedRangeValue) == AXValueGetTypeID() else {
            return nil
        }

        let selectedRange = selectedRangeValue as! AXValue
        guard AXValueGetType(selectedRange) == .cfRange else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(selectedRange, .cfRange, &range) else {
            return nil
        }
        return range
    }

    private static func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value
    }

    private static func postDeleteKey() throws {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false) else {
            throw PasteError.keyboardEventCreationFailed
        }
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

enum PasteError: LocalizedError, Equatable {
    case accessibilityPermissionMissing
    case keyboardEventCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionMissing:
            "\(AppBrand.englishName) 需要辅助功能权限，才能把整理后的文字粘贴到当前输入框。"
        case .keyboardEventCreationFailed:
            "\(AppBrand.englishName) 没能创建粘贴快捷键事件。"
        }
    }
}
