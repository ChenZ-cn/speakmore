import ApplicationServices
import AVFoundation
import Foundation

protocol MicrophonePermissionClient {
    var audioAuthorizationStatus: AVAuthorizationStatus { get }
    func requestAudioAccess(completionHandler: @escaping @Sendable (Bool) -> Void)
}

enum PermissionPrompter {
    @MainActor
    static func promptForAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else {
            return
        }

        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @MainActor
    static func promptForMicrophoneIfNeeded(
        permissionClient: MicrophonePermissionClient = SystemMicrophonePermissionClient()
    ) {
        guard permissionClient.audioAuthorizationStatus == .notDetermined else {
            return
        }

        permissionClient.requestAudioAccess { granted in
            NSLog("\(AppBrand.englishName) microphone permission request completed: \(granted)")
        }
    }
}

private struct SystemMicrophonePermissionClient: MicrophonePermissionClient {
    var audioAuthorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func requestAudioAccess(completionHandler: @escaping @Sendable (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: completionHandler)
    }
}
