

import SwiftUI

// MARK: - 🌙 Lullaby Onboarding View — Main Container

struct LullabyOnboardingView: View {

    @EnvironmentObject var nestMemory: NestMemory
    @StateObject private var brain = LullabyOnboardingBrain()

    var body: some View {
        ZStack {
            StarryNestBackground(particleCount: 20, showAura: true)

            VStack(spacing: 0) {
                // Page indicator
                nestStepIndicator
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                // Pages
                TabView(selection: $brain.currentLullaby) {
                    welcomeNestPage.tag(OnboardingLullaby.welcome)
                    profileNestPage.tag(OnboardingLullaby.childProfile)
                    templateNestPage.tag(OnboardingLullaby.templatePick)
                    reminderNestPage.tag(OnboardingLullaby.reminderStyle)
                    readyNestPage.tag(OnboardingLullaby.nestReady)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: brain.currentLullaby)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .hideKeyboardOnTap()
        .onAppear {
            brain.attachMemory(nestMemory)
        }
    }

    // MARK: – Step Indicator

    private var nestStepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingLullaby.allCases, id: \.self) { step in
                Capsule()
                    .fill(
                        step == brain.currentLullaby
                        ? NestPalette.honeyGlow
                        : NestPalette.lullabyGray
                    )
                    .frame(
                        width: step == brain.currentLullaby ? 28 : 8,
                        height: 4
                    )
                    .animation(.spring(response: 0.35), value: brain.currentLullaby)
            }
        }
        .padding(.horizontal, NestDimensions.nestPadding)
    }

    // MARK: - 📄 Page 1 — Welcome

    private var welcomeNestPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon cluster
            ZStack {
                Circle()
                    .fill(NestPalette.firstLightHaze)
                    .frame(width: 160, height: 160)
                    .nestPulseGlow(radius: 20)

                VStack(spacing: 4) {
                    Text("🌙")
                        .font(.system(size: 64))
                        .nestFloating(amplitude: 5, duration: 3)
                }
            }
            .nestFadeIn(delay: 0.2)
            .padding(.bottom, 40)

            Text("Welcome to \(NestAppName.displayName)")
                .font(NestTypography.cradleTitle)
                .foregroundColor(NestPalette.parentVoice)
                .nestFadeIn(delay: 0.4)

            Text("Daily routine, without the stress")
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.tenderWhisper)
                .padding(.top, 8)
                .nestFadeIn(delay: 0.6)

            // Feature bullets
            VStack(alignment: .leading, spacing: 16) {
                welcomeFeatureRow(
                    icon: "clock.fill",
                    title: "Flexible Timeline",
                    subtitle: "Drag, move, adjust — one tap",
                    delay: 0.8
                )
                welcomeFeatureRow(
                    icon: "bell.badge",
                    title: "Gentle Reminders",
                    subtitle: "Calm nudges, not alarms",
                    delay: 1.0
                )
                welcomeFeatureRow(
                    icon: "star.fill",
                    title: "Grow Together",
                    subtitle: "Earn stardust for every block",
                    delay: 1.2
                )
            }
            .padding(.top, 36)
            .padding(.horizontal, 32)

            Spacer()

            // CTA
            Button {
                brain.stepForward()
            } label: {
                Text("Begin Your Journey")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NestPrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .nestFadeIn(delay: 1.4)
        }
    }

    private func welcomeFeatureRow(
        icon: String,
        title: String,
        subtitle: String,
        delay: Double
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(NestPalette.honeyGlow.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(NestPalette.honeyGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NestTypography.sproutLabel)
                    .foregroundColor(NestPalette.parentVoice)

                Text(subtitle)
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.tenderWhisper)
            }

            Spacer()
        }
        .nestFadeIn(delay: delay)
    }

    // MARK: - 📄 Page 2 — Child Profile

    private var profileNestPage: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Your Little One")
                    .font(NestTypography.cradleTitle)
                    .foregroundColor(NestPalette.parentVoice)
                    .padding(.top, 40)
                    .nestFadeIn(delay: 0.2)

                Text("We'll tailor the day just right")
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)
                    .padding(.top, 6)
                    .nestFadeIn(delay: 0.3)

                // Avatar picker
                avatarNestPicker
                    .padding(.top, 32)
                    .nestFadeIn(delay: 0.4)

                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name (optional)")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)

                    TextField("", text: $brain.childNameDraft)
                        .placeholder(when: brain.childNameDraft.isEmpty) {
                            Text("Little star's name")
                                .foregroundColor(NestPalette.drowsyHint)
                        }
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.parentVoice)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                                .fill(NestPalette.sleepyCharcoal)
                                .overlay(
                                    RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                                        .stroke(NestPalette.dreamlineDivider, lineWidth: 1)
                                )
                        )
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .nestFadeIn(delay: 0.5)

                // Age group picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Age Group")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)
                        .padding(.horizontal, 32)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(AgeNestGroup.allCases) { group in
                                ageNestChip(group)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 24)
                .nestFadeIn(delay: 0.6)

                // Hint
                Text("You can always change this later")
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.drowsyHint)
                    .padding(.top, 20)
                    .nestFadeIn(delay: 0.7)

                // CTA
                Button {
                    brain.stepForward()
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NestPrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, 40)
                .nestFadeIn(delay: 0.8)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var avatarNestPicker: some View {
        VStack(spacing: 12) {
            // Selected avatar large
            ZStack {
                Circle()
                    .fill(NestPalette.sleepyCharcoal)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(NestPalette.honeyGlow.opacity(0.4), lineWidth: 2)
                    )

                Text(brain.selectedAvatarEmoji)
                    .font(.system(size: 40))
            }

            // Emoji options row — horizontal scroll for small screens
            let avatarOptions = ["👶", "🧒", "👧", "👦", "🐣", "🦁", "🐰", "🌟"]
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(avatarOptions, id: \.self) { emoji in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                brain.selectedAvatarEmoji = emoji
                            }
                        } label: {
                            Text(emoji)
                                .font(.system(size: 26))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(
                                            brain.selectedAvatarEmoji == emoji
                                            ? NestPalette.honeyGlow.opacity(0.2)
                                            : NestPalette.lullabyGray.opacity(0.5)
                                        )
                                )
                                .scaleEffect(brain.selectedAvatarEmoji == emoji ? 1.15 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, NestDimensions.nestPadding)
            }
        }
    }

    private func ageNestChip(_ group: AgeNestGroup) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                brain.selectedAgeGroup = group
            }
        } label: {
            VStack(spacing: 6) {
                Text(group.iconSymbol)
                    .font(.system(size: 24))

                Text(group.shortLabel)
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(
                        brain.selectedAgeGroup == group
                        ? NestPalette.midnightNest
                        : NestPalette.tenderWhisper
                    )
            }
            .frame(width: 64, height: 72)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                    .fill(
                        brain.selectedAgeGroup == group
                        ? NestPalette.honeyGlow
                        : NestPalette.sleepyCharcoal
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                    .stroke(
                        brain.selectedAgeGroup == group
                        ? NestPalette.sunriseKiss.opacity(0.5)
                        : NestPalette.dreamlineDivider.opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - 📄 Page 3 — Template Pick (optional)

    private var templateNestPage: some View {
        VStack(spacing: 0) {
            Text("How to Start?")
                .font(NestTypography.cradleTitle)
                .foregroundColor(NestPalette.parentVoice)
                .padding(.top, 40)
                .nestFadeIn(delay: 0.2)

            Text("Empty day or use a template — you can always add blocks or apply templates later")
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.tenderWhisper)
                .padding(.top, 6)
                .padding(.horizontal, 20)
                .nestFadeIn(delay: 0.3)

            ScrollView {
                VStack(spacing: 14) {
                    // Start empty — default
                    templateEmptyCard
                        .nestFadeIn(delay: 0.35)

                    Text("Or use a template")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.drowsyHint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    ForEach(Array(TemplateStyle.allCases.enumerated()), id: \.element) { index, style in
                        templateNestCard(style, delay: 0.4 + Double(index) * 0.1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }

            if brain.selectedTemplateStyle != nil {
                templatePreviewStrip
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }

            Button {
                brain.stepForward()
            } label: {
                Text(brain.selectedTemplateStyle == nil ? "Start with Empty Day" : "Apply Template")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NestPrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .nestFadeIn(delay: 0.8)
        }
    }

    private var templateEmptyCard: some View {
        let isSelected = brain.selectedTemplateStyle == nil

        return Button {
            withAnimation(.spring(response: 0.35)) {
                brain.selectedTemplateStyle = nil
            }
        } label: {
            HStack(spacing: 14) {
                Text("🪹")
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(NestPalette.honeyGlow.opacity(isSelected ? 0.2 : 0.08))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start with empty day")
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)
                    Text("Add blocks yourself or apply a template later")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(NestPalette.honeyGlow)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .fill(NestPalette.sleepyCharcoal)
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .stroke(
                                isSelected ? NestPalette.honeyGlow.opacity(0.5) : NestPalette.dreamlineDivider.opacity(0.4),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func templateNestCard(_ style: TemplateStyle, delay: Double) -> some View {
        let isSelected = brain.selectedTemplateStyle == style

        return Button {
            withAnimation(.spring(response: 0.35)) {
                brain.selectedTemplateStyle = style
            }
        } label: {
            HStack(spacing: 14) {
                Text(style.emoji)
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(NestPalette.honeyGlow.opacity(isSelected ? 0.2 : 0.08))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayTitle)
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)

                    Text(templateSubtitle(for: style))
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(NestPalette.honeyGlow)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .fill(NestPalette.sleepyCharcoal)
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .stroke(
                                isSelected ? NestPalette.honeyGlow.opacity(0.5) : NestPalette.dreamlineDivider.opacity(0.4),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .nestFadeIn(delay: delay)
    }

    private func templateSubtitle(for style: TemplateStyle) -> String {
        switch style {
        case .calm:       return "Longer naps, gentle flow, minimal transitions"
        case .active:     return "More outdoor time, engaging play sessions"
        case .structured: return "Consistent timing, clear blocks, routines"
        }
    }

    private var templatePreviewStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(NestTypography.whisperCaption)
                .foregroundColor(NestPalette.drowsyHint)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(brain.previewBlocks) { block in
                        VStack(spacing: 3) {
                            Image(systemName: block.blockKind.sfIcon)
                                .font(.system(size: 12))
                                .foregroundColor(NestPalette.honeyGlow)

                            Text(block.blockKind.displayTitle)
                                .font(NestTypography.tinyFootprint)
                                .foregroundColor(NestPalette.tenderWhisper)
                        }
                        .frame(width: 52, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(NestPalette.lullabyGray)
                        )
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeOut(duration: 0.3), value: brain.selectedTemplateStyle)
    }

    // MARK: - 📄 Page 4 — Reminder Style

    private var reminderNestPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bell animation
            ZStack {
                Circle()
                    .fill(NestPalette.firstLightHaze)
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundColor(NestPalette.honeyGlow)
                    .nestFloating(amplitude: 3, duration: 2.5)
            }
            .nestFadeIn(delay: 0.2)
            .padding(.bottom, 28)

            Text("Notification Style")
                .font(NestTypography.cradleTitle)
                .foregroundColor(NestPalette.parentVoice)
                .nestFadeIn(delay: 0.3)

            Text("How should we nudge you?")
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.tenderWhisper)
                .padding(.top, 6)
                .nestFadeIn(delay: 0.4)

            VStack(spacing: 12) {
                ForEach(Array(ReminderStyle.allCases.enumerated()), id: \.element.rawValue) { index, style in
                    reminderStyleNestRow(style, delay: 0.5 + Double(index) * 0.15)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)

            Spacer()

            Text("Adjustable anytime in Settings")
                .font(NestTypography.whisperCaption)
                .foregroundColor(NestPalette.drowsyHint)
                .padding(.bottom, 12)

            Button {
                NestNotificationService.shared.requestAuthorization { _ in
                    brain.stepForward()
                }
            } label: {
                Text("Almost There")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NestPrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .nestFadeIn(delay: 0.9)
        }
    }

    private func reminderStyleNestRow(_ style: ReminderStyle, delay: Double) -> some View {
        let isSelected = brain.selectedReminderStyle == style

        return Button {
            withAnimation(.spring(response: 0.3)) {
                brain.selectedReminderStyle = style
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: style.sfIcon)
                    .font(.system(size: 20))
                    .foregroundColor(
                        isSelected ? NestPalette.midnightNest : NestPalette.honeyGlow
                    )
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? NestPalette.honeyGlow : NestPalette.honeyGlow.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(style.displayTitle)
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)

                    Text(style.subtitle)
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(NestPalette.honeyGlow)
                        .transition(.scale)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .fill(NestPalette.sleepyCharcoal)
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .stroke(
                                isSelected ? NestPalette.honeyGlow.opacity(0.4) : NestPalette.dreamlineDivider.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
        }
        .nestFadeIn(delay: delay)
    }

    // MARK: - 📄 Page 5 — Nest Ready

    private var readyNestPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Celebration cluster
            ZStack {
                // Outer pulsing ring
                Circle()
                    .stroke(NestPalette.honeyGlow.opacity(0.2), lineWidth: 2)
                    .frame(width: 160, height: 160)
                    .nestPulseGlow(radius: 16)

                Circle()
                    .fill(NestPalette.honeyGlow.opacity(0.08))
                    .frame(width: 130, height: 130)

                VStack(spacing: 6) {
                    Text("🎉")
                        .font(.system(size: 52))
                        .nestScalePop()

                    Text("+50 ✦")
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.stardustReward)
                        .nestFadeIn(delay: 0.5)
                }
            }
            .padding(.bottom, 32)

            Text("Your Nest is Ready!")
                .font(NestTypography.cradleTitle)
                .foregroundColor(NestPalette.parentVoice)
                .nestFadeIn(delay: 0.3)

            Text("The day is set up for \(brain.childDisplayName)")
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.tenderWhisper)
                .padding(.top, 6)
                .nestFadeIn(delay: 0.5)

            // Quick tips
            VStack(alignment: .leading, spacing: 14) {
                quickTipRow(icon: "hand.tap.fill", text: "Tap any block to mark it done", delay: 0.7)
                quickTipRow(icon: "arrow.up.arrow.down", text: "Drag blocks to rearrange", delay: 0.9)
                quickTipRow(icon: "star.fill", text: "Earn stardust for each completion", delay: 1.1)
            }
            .padding(.horizontal, 36)
            .padding(.top, 32)

            Spacer()

            Button {
                brain.finishOnboarding()
            } label: {
                Text("Let's Go!")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NestPrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
            .nestFadeIn(delay: 1.3)
            .nestPulseGlow(radius: 8)

            Button {
                brain.stepBack()
            } label: {
                Text("Go Back")
            }
            .buttonStyle(NestGhostButtonStyle())
            .padding(.bottom, 40)
            .nestFadeIn(delay: 1.4)
        }
    }

    private func quickTipRow(icon: String, text: String, delay: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NestPalette.honeyGlow)
                .frame(width: 32, height: 32)

            Text(text)
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.tenderWhisper)

            Spacer()
        }
        .nestFadeIn(delay: delay)
    }
}

// MARK: - 🔧 Placeholder Modifier (iOS 16 compatible)

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LullabyOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        LullabyOnboardingView()
            .environmentObject(NestMemory.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
