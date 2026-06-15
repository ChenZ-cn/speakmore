import AppKit
import ApplicationServices
import AVFoundation
import SwiftUI

struct PermissionView: View {
    let language: AppLanguage

    private var strings: AppInterfaceStrings {
        AppInterfaceStrings(language: language)
    }

    init(language: AppLanguage = .system) {
        self.language = language
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.permissions)
                .font(.headline)

            permissionRow(
                title: strings.microphone,
                status: microphoneStatusText,
                buttonTitle: strings.openMicrophonePermission
            ) {
                openPrivacyPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
            }

            permissionRow(
                title: strings.accessibility,
                status: accessibilityStatusText,
                buttonTitle: strings.openAccessibilityPermission
            ) {
                openPrivacyPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            }
        }
    }

    private var microphoneStatusText: String {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            strings.permissionAllowed
        case .denied, .restricted:
            strings.permissionDenied
        case .notDetermined:
            strings.permissionNotAsked
        @unknown default:
            strings.permissionUnknown
        }
    }

    private var accessibilityStatusText: String {
        AXIsProcessTrusted() ? strings.permissionAllowed : strings.permissionDenied
    }

    private func permissionRow(
        title: String,
        status: String,
        buttonTitle: String,
        openAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(buttonTitle, action: openAction)
        }
    }

    private func openPrivacyPane(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
