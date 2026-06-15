import Foundation

struct LocalAPIKeyStore: APIKeyStore {
    let fileURL: URL
    let fallbackFileURL: URL?

    init(
        fileURL: URL = LocalAPIKeyStore.defaultFileURL(),
        fallbackFileURL: URL? = LocalAPIKeyStore.legacyTypelessFileURL()
    ) {
        self.fileURL = fileURL
        self.fallbackFileURL = fallbackFileURL
    }

    func readAPIKey(account: String) -> String? {
        readAllAPIKeys()[account]
    }

    func saveAPIKey(_ apiKey: String, account: String) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        var apiKeys = readAllAPIKeys()
        apiKeys[account] = apiKey

        let data = try PropertyListSerialization.data(
            fromPropertyList: apiKeys,
            format: .xml,
            options: 0
        )
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    private func readAllAPIKeys() -> [String: String] {
        readAPIKeys(from: fallbackFileURL).merging(readAPIKeys(from: fileURL)) { _, current in current }
    }

    static func defaultFileURL() -> URL {
        appSupportFileURL(appName: "SpeakMore")
    }

    static func legacyTypelessFileURL() -> URL {
        appSupportFileURL(appName: "Typeless")
    }

    private static func appSupportFileURL(appName: String) -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(appName, isDirectory: true)
            .appendingPathComponent("APIKeys.plist")
    }

    private func readAPIKeys(from url: URL?) -> [String: String] {
        guard let url,
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let apiKeys = plist as? [String: String] else {
            return [:]
        }

        return apiKeys
    }
}
