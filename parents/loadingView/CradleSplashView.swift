// CradleSplashView.swift
// с17 — Daily Routine Without Stress
// Loading / Splash screen with animations and abstract texts

import SwiftUI

// MARK: - 🌙 Cradle Splash View — Loading Screen

/// Premium animated splash screen shown on app launch.
/// Abstract poetic texts, gold shimmer, floating elements.
struct CradleSplashView: View {

    @State private var currentPhrase: Int = 0
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var textOpacity: Double = 0
    @State private var progressWidth: CGFloat = 0
    @State private var dotsCount: Int = 0
    @State private var isFinished: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var dotsTimer: Timer?

    /// Called when loading is complete.
    var onNestReady: () -> Void

    // Abstract loading phrases — calm and poetic
    private let lullabyPhrases: [String] = [
        "Warming up the nest…",
        "Gathering stardust…",
        "Preparing gentle rhythms…",
        "Lighting the nightlight…",
        "Almost cozy…"
    ]

    var body: some View {
        ZStack {
            // Animated background
            StarryNestBackground(particleCount: 25, showAura: true)

            VStack(spacing: 0) {
                Spacer()

                // Logo cluster
                logoSection
                    .padding(.bottom, 40)

                // Rotating phrase
                phraseSection
                    .padding(.bottom, 48)

                // Progress bar
                progressSection
                    .padding(.horizontal, 60)
                    .padding(.bottom, 16)

                // Dots animation
                loadingDotsSection
                    .padding(.bottom, 8)

                Spacer()

                // Bottom tagline
                bottomTagline
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startSplashSequence()
        }
        .onDisappear {
            dotsTimer?.invalidate()
            dotsTimer = nil
        }
    }

    // MARK: – Logo Section

    private var logoSection: some View {
        ZStack {
            // Outer rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            NestPalette.honeyGlow.opacity(0.5),
                            NestPalette.honeyGlow.opacity(0.05),
                            NestPalette.sunriseKiss.opacity(0.3),
                            NestPalette.honeyGlow.opacity(0.5)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(ringRotation))
                .scaleEffect(ringScale)
                .opacity(logoOpacity)

            // Inner glow circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            NestPalette.honeyGlow.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .opacity(logoOpacity)

            // Moon icon
            VStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 42))
                    .foregroundColor(NestPalette.honeyGlow)
                    .shadow(color: NestPalette.honeyGlow.opacity(0.5), radius: 12)

                Text(NestAppName.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(NestPalette.moonlightWhisper)
                    .tracking(1)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .nestFloating(amplitude: 4, duration: 3.5)
    }

    // MARK: – Phrase Section

    private var phraseSection: some View {
        ZStack {
            ForEach(0..<lullabyPhrases.count, id: \.self) { index in
                Text(lullabyPhrases[index])
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)
                    .opacity(currentPhrase == index ? textOpacity : 0)
                    .scaleEffect(currentPhrase == index ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 0.5), value: currentPhrase)
            }
        }
        .frame(height: 24)
    }

    // MARK: – Progress Bar

    private var progressSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(NestPalette.lullabyGray)
                    .frame(height: 4)

                // Fill
                Capsule()
                    .fill(NestGradients.sunrisePath)
                    .frame(width: progressWidth * geo.size.width, height: 4)
                    .shadow(color: NestPalette.honeyGlow.opacity(0.4), radius: 6)

                // Glow dot at tip
                if progressWidth > 0.02 {
                    Circle()
                        .fill(NestPalette.sunriseKiss)
                        .frame(width: 8, height: 8)
                        .shadow(color: NestPalette.honeyGlow.opacity(0.6), radius: 4)
                        .offset(x: progressWidth * geo.size.width - 4)
                        .nestPulseGlow(radius: 6)
                }
            }
        }
        .frame(height: 8)
    }

    // MARK: – Loading Dots

    private var loadingDotsSection: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < dotsCount
                          ? NestPalette.honeyGlow
                          : NestPalette.lullabyGray
                    )
                    .frame(width: 6, height: 6)
                    .scaleEffect(index < dotsCount ? 1.2 : 0.8)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.5)
                        .delay(Double(index) * 0.12),
                        value: dotsCount
                    )
            }
        }
    }

    // MARK: – Bottom Tagline

    private var bottomTagline: some View {
        VStack(spacing: 4) {
            if showSubtitle {
                Text("Daily routine without stress")
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.drowsyHint)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(height: 20)
        .animation(.easeOut(duration: 0.8), value: showSubtitle)
    }

    // MARK: - 🎬 Animation Sequence

    private func startSplashSequence() {

        // Phase 1 — Logo appears (0.0s)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
            ringScale = 1.0
        }

        // Ring starts rotating
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Phase 2 — First phrase (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 0.4)) {
                textOpacity = 1.0
            }
            startPhraseRotation()
        }

        // Phase 3 — Progress bar fills (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 3.0)) {
                progressWidth = 1.0
            }
        }

        // Phase 4 — Dots animate (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            startDotsAnimation()
        }

        // Phase 5 — Subtitle (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSubtitle = true
        }

        // Phase 6 — Finish (3.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            finishSplash()
        }
    }

    private func startPhraseRotation() {
        // Rotate through phrases every ~0.7s
        for i in 1..<lullabyPhrases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    textOpacity = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    currentPhrase = i
                    withAnimation(.easeInOut(duration: 0.3)) {
                        textOpacity = 1.0
                    }
                }
            }
        }
    }

    private func startDotsAnimation() {
        dotsTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            if isFinished {
                timer.invalidate()
                return
            }
            dotsCount = (dotsCount + 1) % 4
        }
        dotsTimer = timer
    }

    private func finishSplash() {
        isFinished = true
        withAnimation(.easeOut(duration: 0.4)) {
            logoScale = 1.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onNestReady()
        }
    }
}

// MARK: - 🌟 Splash Transition Wrapper

/// Manages the splash → main app transition with a fade.
struct CradleSplashGate: View {

    @State private var showSplash = true
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            // Main content behind
            if !showSplash {
                ParentNestRootGate()
                    .transition(.opacity)
            }

            // Splash on top
            if showSplash {
                CradleSplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        fadeOut = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                }
                .opacity(fadeOut ? 0 : 1)
            }
        }
    }
}

// MARK: - 🚪 Root Gate — Decides Onboarding vs Main

/// After splash, checks if onboarding is done.
struct ParentNestRootGate: View {

    @StateObject private var nestMemory = NestMemory.shared

    var body: some View {
        if nestMemory.hasCompletedOnboarding {
            ParentNestTabView()
                .environmentObject(nestMemory)
        } else {
            LullabyOnboardingView()
                .environmentObject(nestMemory)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CradleSplashView_Previews: PreviewProvider {
    static var previews: some View {
        CradleSplashView(onNestReady: {})
            .preferredColorScheme(.dark)
    }
}
#endif
