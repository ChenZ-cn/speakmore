import AVFoundation
import XCTest
@testable import SpeakMore

final class PermissionPrompterTests: XCTestCase {
    @MainActor
    func testRequestsMicrophoneWhenPermissionIsNotDetermined() {
        let client = FakeMicrophonePermissionClient(status: .notDetermined)

        PermissionPrompter.promptForMicrophoneIfNeeded(permissionClient: client)

        XCTAssertEqual(client.requestAudioAccessCallCount, 1)
    }

    @MainActor
    func testDoesNotRequestMicrophoneWhenPermissionIsAlreadyDecided() {
        let authorizedClient = FakeMicrophonePermissionClient(status: .authorized)
        let deniedClient = FakeMicrophonePermissionClient(status: .denied)

        PermissionPrompter.promptForMicrophoneIfNeeded(permissionClient: authorizedClient)
        PermissionPrompter.promptForMicrophoneIfNeeded(permissionClient: deniedClient)

        XCTAssertEqual(authorizedClient.requestAudioAccessCallCount, 0)
        XCTAssertEqual(deniedClient.requestAudioAccessCallCount, 0)
    }
}

private final class FakeMicrophonePermissionClient: MicrophonePermissionClient {
    private let status: AVAuthorizationStatus
    private(set) var requestAudioAccessCallCount = 0

    init(status: AVAuthorizationStatus) {
        self.status = status
    }

    var audioAuthorizationStatus: AVAuthorizationStatus {
        status
    }

    func requestAudioAccess(completionHandler: @escaping @Sendable (Bool) -> Void) {
        requestAudioAccessCallCount += 1
        completionHandler(true)
    }
}
