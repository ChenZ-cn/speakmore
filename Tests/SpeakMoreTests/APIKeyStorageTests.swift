import Foundation
import XCTest
@testable import SpeakMore

final class APIKeyStorageTests: XCTestCase {
    func testLocalStoreSavesAndReadsAPIKeys() throws {
        let fileURL = temporaryFileURL()
        let store = LocalAPIKeyStore(fileURL: fileURL, fallbackFileURL: nil)

        try store.saveAPIKey("primary-key", account: "openai")
        try store.saveAPIKey("backup-key", account: "openai-backup")

        XCTAssertEqual(store.readAPIKey(account: "openai"), "primary-key")
        XCTAssertEqual(store.readAPIKey(account: "openai-backup"), "backup-key")
    }

    func testLocalStoreReadsLegacyTypelessFileWhenSpeakMoreFileIsEmpty() throws {
        let speakMoreFileURL = temporaryFileURL()
        let legacyFileURL = temporaryFileURL()
        let legacyStore = LocalAPIKeyStore(fileURL: legacyFileURL, fallbackFileURL: nil)
        let store = LocalAPIKeyStore(fileURL: speakMoreFileURL, fallbackFileURL: legacyFileURL)

        try legacyStore.saveAPIKey("legacy-key", account: "openai")

        XCTAssertEqual(store.readAPIKey(account: "openai"), "legacy-key")
    }

    func testResolverUsesLocalStoreWithoutReadingFallback() throws {
        let local = CapturingAPIKeyStore(apiKeys: ["openai": " local-key "])
        let fallback = CapturingAPIKeyStore(apiKeys: ["openai": "keychain-key"])
        let resolver = APIKeyResolver(primaryStore: local, fallbackStore: fallback)

        XCTAssertEqual(resolver.apiKeys(), ["local-key"])
        XCTAssertEqual(local.readAccounts, ["openai", "openai-backup"])
        XCTAssertEqual(fallback.readAccounts, [])
    }

    func testResolverFallsBackWhenLocalStoreIsEmpty() throws {
        let local = CapturingAPIKeyStore(apiKeys: [:])
        let fallback = CapturingAPIKeyStore(apiKeys: ["openai": "keychain-key"])
        let resolver = APIKeyResolver(primaryStore: local, fallbackStore: fallback)

        XCTAssertEqual(resolver.apiKeys(), ["keychain-key"])
        XCTAssertEqual(fallback.readAccounts, ["openai", "openai-backup"])
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("plist")
    }
}

private final class CapturingAPIKeyStore: APIKeyStore {
    private let apiKeys: [String: String]
    private(set) var readAccounts: [String] = []

    init(apiKeys: [String: String]) {
        self.apiKeys = apiKeys
    }

    func readAPIKey(account: String) -> String? {
        readAccounts.append(account)
        return apiKeys[account]
    }

    func saveAPIKey(_ apiKey: String, account: String) throws {}
}
