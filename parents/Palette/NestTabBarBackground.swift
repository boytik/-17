// NestTabBarBackground.swift
// Little Days: Quiet Mind
// Shared native tab bar background — used by ParentNestTabView and NestDocumentNavBar

import SwiftUI

// MARK: - 🎨 Nest Tab Bar Background — Native App Style

/// Native app tab bar / nav bar background: dark surface, gold separator, subtle glow.
/// Reused for consistency between native tabs and document WebView nav bar.
struct NestTabBarBackground: View {

    var body: some View {
        ZStack(alignment: .top) {
            // Blur-like dark surface
            Rectangle()
                .fill(NestPalette.midnightNest.opacity(0.92))

            // Top separator with gold hint
            LinearGradient(
                colors: [
                    NestPalette.honeyGlow.opacity(0.15),
                    NestPalette.honeyGlow.opacity(0.03),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 1)

            // Subtle inner glow
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            NestPalette.sleepyCharcoal.opacity(0.4),
                            NestPalette.midnightNest.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 12)
        }
    }
}
