//
//  BadgeDetailNestSheet.swift
//  parents
//
//  Created by Евгений on 18.02.2026.
//

import SwiftUI

struct BadgeDetailNestSheet: View {

    let badge: NestBadge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            VStack(spacing: 24) {
                // Close
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(NestPalette.drowsyHint)
                    }
                }

                // Badge icon
                ZStack {
                    Circle()
                        .fill(NestPalette.honeyGlow.opacity(0.1))
                        .frame(width: 100, height: 100)

                    if badge.isUnlocked {
                        Circle()
                            .stroke(NestPalette.honeyGlow.opacity(0.4), lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .nestPulseGlow(radius: 12)
                    }

                    Text(badge.emoji)
                        .font(.system(size: 48))
                        .opacity(badge.isUnlocked ? 1.0 : 0.4)
                }
                .nestFloating(amplitude: 4, duration: 3)

                // Title
                Text(badge.title)
                    .font(NestTypography.cradleTitle)
                    .foregroundColor(NestPalette.parentVoice)

                // Description
                Text(badge.description)
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Status
                if badge.isUnlocked, let date = badge.unlockedAt {
                    let formatter: DateFormatter = {
                        let f = DateFormatter()
                        f.dateStyle = .medium
                        return f
                    }()

                    Text("Unlocked \(formatter.string(from: date))")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.honeyGlow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(NestPalette.honeyGlow.opacity(0.1))
                        )
                } else {
                    Text("🔒 Not yet unlocked")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.drowsyHint)
                }

                Spacer()
            }
            .padding(20)
        }
    }
}
