import AppKit

struct ClipboardSnapshot {
    let items: [[NSPasteboard.PasteboardType: Data]]
}

final class ClipboardController {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func string() -> String? {
        pasteboard.string(forType: .string)
    }

    func snapshot() -> ClipboardSnapshot {
        let items = pasteboard.pasteboardItems?.map { item in
            item.types.reduce(into: [NSPasteboard.PasteboardType: Data]()) { result, type in
                result[type] = item.data(forType: type)
            }
        } ?? []

        return ClipboardSnapshot(items: items)
    }

    func writeText(_ text: String) {
        _ = writeTextReturningChangeCount(text)
    }

    func writeTextReturningChangeCount(_ text: String) -> Int {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        return pasteboard.changeCount
    }

    func restore(_ snapshot: ClipboardSnapshot) {
        restoreSnapshot(snapshot)
    }

    @discardableResult
    func restore(_ snapshot: ClipboardSnapshot, ifChangeCountIs expectedChangeCount: Int) -> Bool {
        guard pasteboard.changeCount == expectedChangeCount else {
            return false
        }

        restoreSnapshot(snapshot)
        return true
    }

    private func restoreSnapshot(_ snapshot: ClipboardSnapshot) {
        pasteboard.clearContents()
        guard !snapshot.items.isEmpty else {
            return
        }

        let pasteboardItems = snapshot.items.map { itemDataByType in
            let item = NSPasteboardItem()
            for (type, data) in itemDataByType {
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(pasteboardItems)
    }
}
