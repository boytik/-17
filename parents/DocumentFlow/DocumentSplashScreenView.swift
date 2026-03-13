// DocumentSplashScreenView.swift
// Little Days: Quiet Mind
// Loading screen during flow validations — native app style

import SwiftUI

// MARK: - 🌙 Document Splash Screen — Native Style

struct DocumentSplashScreenView: View {

    var body: some View {
        ZStack {
            StarryNestBackground(particleCount: 25, showAura: true)

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(NestPalette.honeyGlow)

                Text(NestAppName.displayName)
                    .font(NestTypography.cradleTitle)
                    .foregroundColor(NestPalette.parentVoice)

                Text("Warming up the nest…")
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)
                    .padding(.top, 8)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NestPalette.honeyGlow))
                    .scaleEffect(1.2)
                    .padding(.top, 24)

                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}
