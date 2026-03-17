// ReminderPermissionButton.swift
// Shows notification permission status and allows re-request

import SwiftUI
import UserNotifications

struct ReminderPermissionButton: View {

    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Group {
            switch authStatus {
            case .authorized, .provisional:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(NestPalette.calmBreath)
                    Text(NSLocalizedString("Notifications enabled", comment: ""))
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.tenderWhisper)
                }
                .padding(.vertical, 8)

            case .denied:
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                        Text(NSLocalizedString("Notifications off — tap to open Settings", comment: ""))
                    }
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.gentleBlush)
                }
                .padding(.vertical, 8)

            case .notDetermined:
                Button {
                    NestNotificationService.shared.requestAuthorization { _ in
                        NestNotificationService.shared.checkAuthorizationStatus { status in
                            authStatus = status
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge")
                        Text(NSLocalizedString("Enable notifications for reminders", comment: ""))
                    }
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.honeyGlow)
                }
                .padding(.vertical, 8)

            case .ephemeral:
                EmptyView()

            @unknown default:
                EmptyView()
            }
        }
        .onAppear {
            NestNotificationService.shared.checkAuthorizationStatus { status in
                authStatus = status
            }
        }
    }
}
