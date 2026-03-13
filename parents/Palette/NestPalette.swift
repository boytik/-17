// NestPalette.swift
// с17 — Daily Routine Without Stress
// Theme: Premium Dark — Black, Dark Gold, White

import SwiftUI

// MARK: - 🎨 Nest Colors — The Family Palette

/// All colors named in parent-child metaphor style.
/// Dark premium palette: deep blacks, warm gold accents, soft whites.
enum NestPalette {

    // MARK: – Core Triad

    /// Deep black — the main canvas, like a calm night sky over the nursery.
    static let midnightNest        = Color(hex: "0D0D0F")

    /// Safe area background — warm dark tone for notch/status bar region.
    static let safeAreaNest        = Color(hex: "2D221E")

    /// Dark gold — warm accent, like a nightlight glow in a child's room.
    static let honeyGlow           = Color(hex: "B8860B")

    /// Soft white — text and highlights, like moonlight through curtains.
    static let moonlightWhisper    = Color(hex: "F5F0E8")

    // MARK: – Extended Dark Tones

    /// Slightly lighter dark — cards and elevated surfaces.
    static let sleepyCharcoal      = Color(hex: "1A1A1E")

    /// Medium dark — secondary surfaces, borders.
    static let lullabyGray         = Color(hex: "2A2A30")

    /// Subtle separator lines.
    static let dreamlineDivider    = Color(hex: "3A3A42")

    // MARK: – Gold Variations

    /// Lighter gold — for highlights and progress.
    static let sunriseKiss         = Color(hex: "D4A636")

    /// Very faint gold — subtle glow behind elements.
    static let firstLightHaze      = Color(hex: "B8860B").opacity(0.15)

    /// Deep amber — for completed/success states.
    static let goldenCradle        = Color(hex: "DAA520")

    // MARK: – Semantic — Status Colors

    /// Gentle green — "done" status, like a peaceful sleeping baby.
    static let calmBreath          = Color(hex: "3A7D44")

    /// Soft coral — "skipped" status, no guilt tone.
    static let gentleBlush         = Color(hex: "C75C5C")

    /// Muted blue — "moved" status, calm and informational.
    static let driftingCloud       = Color(hex: "5B7FA5")

    /// Warm orange — "in progress", active moment.
    static let playfulSunbeam      = Color(hex: "D48B2E")

    // MARK: – Text Hierarchy

    /// Primary text — high contrast on dark.
    static let parentVoice         = Color(hex: "F5F0E8")

    /// Secondary text — softer, like a whisper.
    static let tenderWhisper       = Color(hex: "A0A0A8")

    /// Tertiary / disabled text.
    static let drowsyHint          = Color(hex: "606068")

    // MARK: – Gamification Accents

    /// XP bar fill — bright gold energy.
    static let stardustReward      = Color(hex: "FFD700")

    /// Level badge glow.
    static let crownShimmer        = Color(hex: "E6BE44")

    /// Streak fire accent.
    static let heartbeatStreak     = Color(hex: "FF8C42")

    /// Achievement unlock pulse.
    static let sproutSparkle       = Color(hex: "A8E06C")
}



// MARK: - 🎭 Nest Gradients

enum NestGradients {

    /// Main background gradient — subtle depth.
    static let nightSkyBlanket = LinearGradient(
        colors: [
            NestPalette.midnightNest,
            Color(hex: "111115"),
            Color(hex: "0A0A0D")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Card glow — subtle gold edge.
    static let honeyEdge = LinearGradient(
        colors: [
            NestPalette.honeyGlow.opacity(0.4),
            NestPalette.honeyGlow.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Progress bar fill.
    static let sunrisePath = LinearGradient(
        colors: [
            NestPalette.honeyGlow,
            NestPalette.sunriseKiss
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Achievement badge shimmer.
    static let crownGlow = LinearGradient(
        colors: [
            NestPalette.crownShimmer,
            NestPalette.stardustReward,
            NestPalette.crownShimmer
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Splash screen radial glow.
    static let cradleAura = RadialGradient(
        colors: [
            NestPalette.honeyGlow.opacity(0.2),
            NestPalette.midnightNest
        ],
        center: .center,
        startRadius: 50,
        endRadius: 400
    )
}


// MARK: - 🌓 Nest Shadows

enum NestShadows {

    /// Subtle card elevation.
    static func cradleLift(_ isLifted: Bool = true) -> some View {
        EmptyView()
            .shadow(
                color: NestPalette.honeyGlow.opacity(isLifted ? 0.15 : 0),
                radius: isLifted ? 12 : 0,
                x: 0,
                y: isLifted ? 4 : 0
            )
    }
}

// MARK: - 🛠 Color Hex Initializer

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)

        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}


/// Secondary / ghost button style.
struct NestGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NestTypography.sproutLabel)
            .foregroundColor(NestPalette.honeyGlow)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .stroke(NestPalette.honeyGlow.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {

    /// Apply standard nest card styling.
    func nestCard(elevated: Bool = false) -> some View {
        modifier(NestCardModifier(isElevated: elevated))
    }

    /// Hide keyboard on tap.
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}
