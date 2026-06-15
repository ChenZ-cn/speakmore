import Network
import XCTest
@testable import SpeakMore

final class NetworkAvailabilityCheckerTests: XCTestCase {
    func testRequiresConnectionIsTreatedAsUnavailable() {
        XCTAssertTrue(NetworkAvailabilityChecker.isNetworkAvailable(for: .satisfied))
        XCTAssertFalse(NetworkAvailabilityChecker.isNetworkAvailable(for: .requiresConnection))
        XCTAssertFalse(NetworkAvailabilityChecker.isNetworkAvailable(for: .unsatisfied))
    }
}
