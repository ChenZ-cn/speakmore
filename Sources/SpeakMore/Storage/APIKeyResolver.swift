import Foundation

struct APIKeyResolver {
    private let primaryStore: APIKeyStore
    private let fallbackStore: APIKeyStore?
    private let accounts: [String]

    init(
        primaryStore: APIKeyStore,
        fallbackStore: APIKeyStore?,
        accounts: [String] = ["openai", "openai-backup"]
    ) {
        self.primaryStore = primaryStore
        self.fallbackStore = fallbackStore
        self.accounts = accounts
    }

    func apiKeys() -> [String] {
        let primaryKeys = readKeys(from: primaryStore)
        if !primaryKeys.isEmpty {
            return primaryKeys
        }

        guard let fallbackStore else {
            return []
        }

        return readKeys(from: fallbackStore)
    }

    private func readKeys(from store: APIKeyStore) -> [String] {
        accounts
            .compactMap { store.readAPIKey(account: $0)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
