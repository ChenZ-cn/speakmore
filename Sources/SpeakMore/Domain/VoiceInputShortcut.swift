import AppKit
import Foundation

enum VoiceInputShortcutTrigger: String, CaseIterable, Codable, Equatable {
    case pressAndHold
    case toggle
}

struct ShortcutModifiers: OptionSet, Codable, Equatable, Hashable {
    let rawValue: Int

    static let control = ShortcutModifiers(rawValue: 1 << 0)
    static let option = ShortcutModifiers(rawValue: 1 << 1)
    static let shift = ShortcutModifiers(rawValue: 1 << 2)
    static let command = ShortcutModifiers(rawValue: 1 << 3)
    static let function = ShortcutModifiers(rawValue: 1 << 4)

    static let allSupported: ShortcutModifiers = [.control, .option, .shift, .command, .function]

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(eventModifierFlags: NSEvent.ModifierFlags) {
        var modifiers: ShortcutModifiers = []
        if eventModifierFlags.contains(.control) { modifiers.insert(.control) }
        if eventModifierFlags.contains(.option) { modifiers.insert(.option) }
        if eventModifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if eventModifierFlags.contains(.command) { modifiers.insert(.command) }
        if eventModifierFlags.contains(.function) { modifiers.insert(.function) }
        self = modifiers
    }

    var displayComponents: [String] {
        var components: [String] = []
        if contains(.control) { components.append("Control") }
        if contains(.option) { components.append("Option") }
        if contains(.shift) { components.append("Shift") }
        if contains(.command) { components.append("Command") }
        if contains(.function) { components.append("Fn") }
        return components
    }
}

struct VoiceInputShortcutBinding: Codable, Equatable, Hashable {
    var modifiers: ShortcutModifiers
    var keyCode: UInt16?
    var charactersIgnoringModifiers: String?

    var isModifierOnly: Bool {
        keyCode == nil
    }

    var displayTitle: String {
        let components = modifiers.displayComponents + keyDisplayComponents
        return components.isEmpty ? "Control" : components.joined(separator: " + ")
    }

    func matches(modifiers eventModifiers: ShortcutModifiers) -> Bool {
        isModifierOnly && modifiers == eventModifiers
    }

    func matches(keyCode eventKeyCode: UInt16, modifiers eventModifiers: ShortcutModifiers) -> Bool {
        keyCode == eventKeyCode && modifiers == eventModifiers
    }

    private var keyDisplayComponents: [String] {
        guard let keyCode else {
            return []
        }

        if keyCode == 49 {
            return ["Space"]
        }

        if keyCode == 36 {
            return ["Return"]
        }

        if keyCode == 48 {
            return ["Tab"]
        }

        if keyCode == 53 {
            return ["Esc"]
        }

        if keyCode == 51 {
            return ["Delete"]
        }

        let character = charactersIgnoringModifiers?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !character.isEmpty {
            return [character.uppercased()]
        }

        return ["Key \(keyCode)"]
    }
}

struct VoiceInputShortcut: Codable, Equatable {
    var trigger: VoiceInputShortcutTrigger
    var binding: VoiceInputShortcutBinding

    static let `default` = VoiceInputShortcut(
        trigger: .pressAndHold,
        binding: .init(modifiers: .control, keyCode: nil, charactersIgnoringModifiers: nil)
    )

    var displayTitle: String {
        binding.displayTitle
    }

    var storageValue: String? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return data.base64EncodedString()
    }

    init(trigger: VoiceInputShortcutTrigger, binding: VoiceInputShortcutBinding) {
        self.trigger = trigger
        self.binding = binding
    }

    init?(storageValue: String) {
        guard let data = Data(base64Encoded: storageValue),
              let shortcut = try? JSONDecoder().decode(VoiceInputShortcut.self, from: data) else {
            return nil
        }
        self = shortcut
    }
}
