// StarryNestBackground.swift
// с17 — Daily Routine Without Stress
// Animated dark background with floating particles and gold glow

import SwiftUI

// MARK: - 🌌 Starry Nest Background — Main Reusable View

/// Animated premium dark background used on every screen.
/// Floating gold particles + subtle radial glow + gentle drift.
struct StarryNestBackground: View {

    @State private var particleSeed: [NestParticle] = []
    @State private var glowPhase: CGFloat = 0
    @State private var driftOffset: CGFloat = 0

    var particleCount: Int = 35
    var showAura: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1 — Deep gradient base
                NestGradients.nightSkyBlanket
                    .ignoresSafeArea()

                // Layer 2 — Radial gold aura (subtle pulse)
                if showAura {
                    auraGlow(in: geo.size)
                }

                // Layer 3 — Floating particles
                ForEach(particleSeed) { particle in
                    ParticleDotView(
                        particle: particle,
                        canvasSize: geo.size,
                        globalDrift: driftOffset
                    )
                }

                // Layer 4 — Soft vignette overlay
                vignetteOverlay(in: geo.size)
            }
            .onAppear {
                seedParticles(in: geo.size)
                startAuraPulse()
                startDrift()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: – Aura Glow

    private func auraGlow(in size: CGSize) -> some View {
        RadialGradient(
            colors: [
                NestPalette.honeyGlow.opacity(0.06 + 0.03 * sin(Double(glowPhase))),
                NestPalette.honeyGlow.opacity(0.02),
                Color.clear
            ],
            center: .center,
            startRadius: 40,
            endRadius: size.width * 0.8
        )
        .scaleEffect(1.0 + 0.05 * sin(Double(glowPhase * 0.7)))
        .ignoresSafeArea()
    }

    // MARK: – Vignette

    private func vignetteOverlay(in size: CGSize) -> some View {
        RadialGradient(
            colors: [
                Color.clear,
                NestPalette.midnightNest.opacity(0.4)
            ],
            center: .center,
            startRadius: size.width * 0.3,
            endRadius: size.width * 0.9
        )
        .ignoresSafeArea()
    }

    // MARK: – Particle Seeding

    private func seedParticles(in size: CGSize) {
        particleSeed = (0..<particleCount).map { index in
            NestParticle(
                id: index,
                originX: CGFloat.random(in: 0...size.width),
                originY: CGFloat.random(in: 0...size.height),
                radius: CGFloat.random(in: 1.2...3.5),
                opacity: Double.random(in: 0.15...0.55),
                speed: Double.random(in: 0.3...1.2),
                phaseOffset: Double.random(in: 0...(.pi * 2)),
                wanderRadius: CGFloat.random(in: 8...30),
                isGold: index % 5 == 0  // every 5th particle is gold
            )
        }
    }

    // MARK: – Animations

    private func startAuraPulse() {
        withAnimation(
            .easeInOut(duration: 6)
            .repeatForever(autoreverses: true)
        ) {
            glowPhase = .pi * 2
        }
    }

    private func startDrift() {
        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            driftOffset = .pi * 2
        }
    }
}

// MARK: - ✨ Particle Model

struct NestParticle: Identifiable {
    let id: Int
    let originX: CGFloat
    let originY: CGFloat
    let radius: CGFloat
    let opacity: Double
    let speed: Double
    let phaseOffset: Double
    let wanderRadius: CGFloat
    let isGold: Bool
}

// MARK: - 💫 Particle Dot View

/// Individual floating dot with subtle oscillation.
struct ParticleDotView: View {

    let particle: NestParticle
    let canvasSize: CGSize
    let globalDrift: CGFloat

    @State private var localPhase: CGFloat = 0

    var body: some View {
        Circle()
            .fill(particleColor)
            .frame(width: particle.radius * 2, height: particle.radius * 2)
            .blur(radius: particle.radius * 0.4)
            .opacity(particle.opacity * (0.6 + 0.4 * sin(localPhase + particle.phaseOffset)))
            .position(
                x: particle.originX + particle.wanderRadius * sin(localPhase * particle.speed + particle.phaseOffset),
                y: particle.originY + particle.wanderRadius * 0.6 * cos(localPhase * particle.speed * 0.8 + particle.phaseOffset)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 10 / particle.speed)
                    .repeatForever(autoreverses: false)
                ) {
                    localPhase = .pi * 2
                }
            }
    }

    private var particleColor: Color {
        particle.isGold
            ? NestPalette.honeyGlow.opacity(0.7)
            : NestPalette.moonlightWhisper.opacity(0.5)
    }
}

// MARK: - 🎆 Background Modifier

/// Convenient modifier to add starry background behind any content.
struct StarryNestBackgroundModifier: ViewModifier {
    var particleCount: Int = 35
    var showAura: Bool = true

    func body(content: Content) -> some View {
        ZStack {
            StarryNestBackground(
                particleCount: particleCount,
                showAura: showAura
            )
            content
        }
    }
}

extension View {
    /// Wraps the view with the animated starry dark background.
    func starryNestBackground(particles: Int = 35, showAura: Bool = true) -> some View {
        modifier(StarryNestBackgroundModifier(particleCount: particles, showAura: showAura))
    }
}

// MARK: - 🌟 Shimmer Effect — For loading states and gold accents

/// A gold shimmer sweep that repeats infinitely.
struct NestShimmerEffect: ViewModifier {

    @State private var shimmerPhase: CGFloat = -1.5

    var duration: Double = 2.0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            NestPalette.sunriseKiss.opacity(0.25),
                            NestPalette.honeyGlow.opacity(0.35),
                            NestPalette.sunriseKiss.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: shimmerPhase * (geo.size.width + geo.size.width * 0.6))
                    .onAppear {
                        withAnimation(
                            .linear(duration: duration)
                            .repeatForever(autoreverses: false)
                        ) {
                            shimmerPhase = 1.5
                        }
                    }
                }
            )
            .mask(content)
    }
}

extension View {
    /// Applies a gold shimmer sweep animation.
    func nestShimmer(duration: Double = 2.0) -> some View {
        modifier(NestShimmerEffect(duration: duration))
    }
}

// MARK: - 💫 Pulsing Glow — For buttons and highlights

struct NestPulseGlow: ViewModifier {

    @State private var isPulsing = false

    var color: Color = NestPalette.honeyGlow
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isPulsing ? 0.35 : 0.1),
                radius: isPulsing ? radius : radius * 0.5,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    /// Adds a pulsing glow effect (gold by default).
    func nestPulseGlow(color: Color = NestPalette.honeyGlow, radius: CGFloat = 12) -> some View {
        modifier(NestPulseGlow(color: color, radius: radius))
    }
}

// MARK: - 🔮 Floating Animation — For onboarding elements

struct NestFloatingModifier: ViewModifier {

    @State private var isFloating = false

    var amplitude: CGFloat = 6
    var duration: Double = 3.0

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating = true
                }
            }
    }
}

extension View {
    /// Makes the view gently float up and down.
    func nestFloating(amplitude: CGFloat = 6, duration: Double = 3.0) -> some View {
        modifier(NestFloatingModifier(amplitude: amplitude, duration: duration))
    }
}

// MARK: - 🌙 Fade-In on Appear

struct NestFadeInModifier: ViewModifier {

    @State private var isVisible = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Fades in with a slight upward slide.
    func nestFadeIn(delay: Double = 0) -> some View {
        modifier(NestFadeInModifier(delay: delay))
    }
}

// MARK: - 🎯 Scale Pop — For badge unlocks and rewards

struct NestScalePopModifier: ViewModifier {

    @State private var didPop = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(didPop ? 1.0 : 0.3)
            .opacity(didPop ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    didPop = true
                }
            }
    }
}

extension View {
    /// Pops in with a spring scale effect.
    func nestScalePop() -> some View {
        modifier(NestScalePopModifier())
    }
}
