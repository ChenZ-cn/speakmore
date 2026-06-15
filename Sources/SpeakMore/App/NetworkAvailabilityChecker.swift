import Foundation
import Network

@MainActor
protocol NetworkAvailabilityChecking {
    var isNetworkAvailable: Bool { get }
}

@MainActor
final class NetworkAvailabilityChecker: NetworkAvailabilityChecking {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "\(AppBrand.englishName).NetworkAvailabilityChecker")
    private var status: NWPath.Status?

    var isNetworkAvailable: Bool {
        guard let status else {
            return true
        }
        return Self.isNetworkAvailable(for: status)
    }

    nonisolated static func isNetworkAvailable(for status: NWPath.Status) -> Bool {
        status == .satisfied
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.status = path.status
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
