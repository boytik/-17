// FamilyNestView.swift
// с17 — Daily Routine Without Stress
// Settings Tab — View only (ViewModel in FamilyNestBrain.swift)

import SwiftUI

// MARK: - ⚙️ Family Nest View — Settings Tab

struct FamilyNestView: View {

    @EnvironmentObject var nestMemory: NestMemory
    @StateObject private var brain = FamilyNestBrain()

    @State private var showParentAvatarPicker = false
    @State private var showChildAvatarPicker = false
    @State private var showAddChildSheet = false
    @State private var showResetConfirmation = false
    @State private var showShareSheet = false
    @State private var showLifetimeStats = false
    @State private var editingProfile: LittleOneProfile? = nil

    var body: some View {
        ZStack {
            StarryNestBackground(particleCount: 15, showAura: false)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    settingsHeader
                        .padding(.top, 12)

                    // Parent avatar card
                    parentAvatarSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Children profiles
                    childProfilesSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Reminder settings
                    reminderSettingsSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Quiet hours
                    quietHoursSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Fun buttons section
                    funActionsSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Danger zone
                    dangerZoneSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // App info
                    appInfoFooter
                        .padding(.top, 8)

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showParentAvatarPicker) {
            ParentEmojiPickerSheet(brain: brain)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddChildSheet) {
            AddChildNestSheet(brain: brain)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingProfile) { profile in
            EditChildNestSheet(profile: profile, brain: brain)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLifetimeStats) {
            LifetimeStatsNestSheet()
                .environmentObject(nestMemory)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSummaryNestSheet(brain: brain)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Reset Everything?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                brain.resetAllData()
            }
        } message: {
            Text("This will erase all profiles, routines, progress, and badges. This cannot be undone.")
        }
        .onAppear {
            brain.attachMemory(nestMemory)
        }
    }

    // MARK: – Header

    private var settingsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Family Nest")
                    .font(NestTypography.cradleTitle)
                    .foregroundColor(NestPalette.parentVoice)

                Text("Your space, your rules")
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)
            }

            Spacer()

            // Quiet mode toggle
            Button {
                brain.toggleQuietMode()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: brain.isQuietMode ? "moon.fill" : "moon")
                        .font(.system(size: 14))

                    Text(brain.isQuietMode ? "Quiet" : "Active")
                        .font(NestTypography.sproutLabel)
                }
                .foregroundColor(
                    brain.isQuietMode ? NestPalette.honeyGlow : NestPalette.tenderWhisper
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(NestPalette.sleepyCharcoal)
                        .overlay(
                            Capsule()
                                .stroke(
                                    brain.isQuietMode
                                    ? NestPalette.honeyGlow.opacity(0.4)
                                    : NestPalette.dreamlineDivider.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
        .padding(.horizontal, NestDimensions.nestPadding)
    }

    // MARK: – Parent Avatar Section

    private var parentAvatarSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Parent Avatar")
                    .font(NestTypography.guardianHeadline)
                    .foregroundColor(NestPalette.parentVoice)

                Spacer()

                Button {
                    showParentAvatarPicker = true
                } label: {
                    Text("Change")
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.honeyGlow)
                }
            }

            HStack(spacing: 16) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(NestPalette.honeyGlow.opacity(0.1))
                        .frame(width: 70, height: 70)

                    Circle()
                        .stroke(NestPalette.honeyGlow.opacity(0.3), lineWidth: 2)
                        .frame(width: 70, height: 70)

                    Text(brain.parentAvatarEmoji)
                        .font(.system(size: 36))
                }

                VStack(alignment: .leading, spacing: 4) {
                    let gp = nestMemory.guardianProgress
                    let level = gp.guardianLevel

                    HStack(spacing: 6) {
                        Text(level.emoji)
                            .font(.system(size: 14))

                        Text(level.displayTitle)
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(NestPalette.parentVoice)
                    }

                    Text("\(gp.totalStardust) ✦ stardust collected")
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.tenderWhisper)

                    Text("\(gp.earnedBadges.count) of \(NestBadgeCatalog.allBadges.count) badges earned")
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.drowsyHint)
                }

                Spacer()
            }
        }
        .nestCard()
    }

    // MARK: – Children Profiles Section

    private var childProfilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Little Ones")
                    .font(NestTypography.guardianHeadline)
                    .foregroundColor(NestPalette.parentVoice)

                Spacer()

                Button {
                    showAddChildSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add")
                            .font(NestTypography.lullabyBody)
                    }
                    .foregroundColor(NestPalette.honeyGlow)
                }
            }

            if nestMemory.profiles.isEmpty {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(NestPalette.drowsyHint)

                    Text("No profiles yet — add your first little one")
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.tenderWhisper)
                }
                .nestCard()
            } else {
                ForEach(nestMemory.profiles) { profile in
                    childProfileRow(profile)
                }
            }
        }
    }

    private func childProfileRow(_ profile: LittleOneProfile) -> some View {
        let isActive = nestMemory.settings.activeProfileId == profile.id

        return HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        isActive
                        ? NestPalette.honeyGlow.opacity(0.15)
                        : NestPalette.lullabyGray.opacity(0.5)
                    )
                    .frame(width: 44, height: 44)

                if isActive {
                    Circle()
                        .stroke(NestPalette.honeyGlow.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 44, height: 44)
                }

                Text(profile.avatarEmoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.petName.isEmpty ? "Little One" : profile.petName)
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)

                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(NestPalette.midnightNest)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(NestPalette.honeyGlow)
                            )
                    }
                }

                Text(profile.ageNestGroup.displayTitle)
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                if !isActive {
                    Button {
                        brain.switchToProfile(profile.id)
                    } label: {
                        Text("Activate")
                            .font(NestTypography.lullabyBody)
                            .foregroundColor(NestPalette.honeyGlow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(NestPalette.honeyGlow.opacity(0.4), lineWidth: 1)
                            )
                    }
                }

                Button {
                    editingProfile = profile
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundColor(NestPalette.tenderWhisper)
                        .frame(width: NestDimensions.touchCradle, height: NestDimensions.touchCradle)
                }
            }
        }
        .nestCard(elevated: isActive)
    }

    // MARK: – Reminder Settings

    private var reminderSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notification Style")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            ReminderPermissionButton()

            ForEach(ReminderStyle.allCases, id: \.rawValue) { style in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        brain.setReminderStyle(style)
                    }
                } label: {
                    reminderStyleRow(style)
                }
            }
        }
    }

    private func reminderStyleRow(_ style: ReminderStyle) -> some View {
        let isSelected = brain.currentReminderStyle == style

        return HStack(spacing: 12) {
            Image(systemName: style.sfIcon)
                .font(.system(size: 18))
                .foregroundColor(
                    isSelected ? NestPalette.midnightNest : NestPalette.honeyGlow
                )
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? NestPalette.honeyGlow : NestPalette.honeyGlow.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(style.displayTitle)
                    .font(NestTypography.sproutLabel)
                    .foregroundColor(NestPalette.parentVoice)

                Text(style.subtitle)
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(NestPalette.honeyGlow)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                .fill(NestPalette.sleepyCharcoal)
                .overlay(
                    RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                        .stroke(
                            isSelected
                            ? NestPalette.honeyGlow.opacity(0.4)
                            : NestPalette.dreamlineDivider.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: – Quiet Hours

    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiet Hours")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            HStack(spacing: 16) {
                // From
                VStack(spacing: 6) {
                    Text("From")
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.drowsyHint)

                    Text(brain.quietHoursStartLabel)
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                        .fill(NestPalette.sleepyCharcoal)
                )

                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                    .foregroundColor(NestPalette.honeyGlow)

                // To
                VStack(spacing: 6) {
                    Text("To")
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.drowsyHint)

                    Text(brain.quietHoursEndLabel)
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                        .fill(NestPalette.sleepyCharcoal)
                )
            }

            // Quick presets — centered
            HStack(spacing: 10) {
                Spacer(minLength: 0)
                quietPresetChip(label: "9 PM – 7 AM", start: 1260, end: 420)
                quietPresetChip(label: "10 PM – 6 AM", start: 1320, end: 360)
                quietPresetChip(label: "8 PM – 8 AM", start: 1200, end: 480)
                Spacer(minLength: 0)
            }
        }
        .nestCard()
    }

    private func quietPresetChip(label: String, start: Int, end: Int) -> some View {
        let isActive = brain.quietStart == start && brain.quietEnd == end

        return Button {
            withAnimation(.spring(response: 0.25)) {
                brain.setQuietHours(start: start, end: end)
            }
        } label: {
            Text(label)
                .font(NestTypography.sproutLabel)
                .foregroundColor(
                    isActive ? NestPalette.midnightNest : NestPalette.tenderWhisper
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isActive ? NestPalette.honeyGlow : NestPalette.lullabyGray)
                )
        }
    }

    // MARK: – Fun Actions Section

    private var funActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Lifetime stats
            funActionRow(
                icon: "chart.pie.fill",
                title: "Lifetime Statistics",
                subtitle: "Your complete parenting journey in numbers",
                color: NestPalette.honeyGlow
            ) {
                showLifetimeStats = true
            }

            // Share summary
            funActionRow(
                icon: "square.and.arrow.up",
                title: "Share Summary",
                subtitle: "Send a snapshot of your week to a partner",
                color: NestPalette.driftingCloud
            ) {
                showShareSheet = true
            }

        }
    }

    private func funActionRow(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(subtitle)
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.tenderWhisper)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(NestPalette.drowsyHint)
            }
            .nestCard()
        }
    }

    // MARK: – Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showResetConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 16))
                        .foregroundColor(NestPalette.gentleBlush)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Data")
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(NestPalette.gentleBlush)

                        Text("Erase everything and start fresh")
                            .font(NestTypography.lullabyBody)
                            .foregroundColor(NestPalette.drowsyHint)
                    }

                    Spacer()
                }
                .nestCard()
            }
        }
    }

    // MARK: – App Info Footer

    private var appInfoFooter: some View {
        VStack(spacing: 6) {
            Text(NestAppName.displayName)
                .font(NestTypography.sproutLabel)
                .foregroundColor(NestPalette.drowsyHint)

            Text("Daily routine without stress")
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.drowsyHint)

            Text("v1.0 • Made with 💛")
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.dreamlineDivider)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }
}

// MARK: - 🎭 Parent Emoji Picker Sheet

struct ParentEmojiPickerSheet: View {

    @ObservedObject var brain: FamilyNestBrain
    @Environment(\.dismiss) private var dismiss

    private let emojiGrid = [
        "🦸", "🦸‍♀️", "🧑‍🍼", "👨‍👩‍👧", "🐻", "🦊",
        "🌻", "🏔", "🎯", "☕️", "🧘", "🌙",
        "🦁", "🐨", "🦋", "🌈", "⭐️", "💎"
    ]

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Choose Your Avatar")
                        .font(NestTypography.guardianHeadline)
                        .foregroundColor(NestPalette.parentVoice)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(NestPalette.drowsyHint)
                    }
                }

                // Current selection
                ZStack {
                    Circle()
                        .fill(NestPalette.honeyGlow.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Circle()
                        .stroke(NestPalette.honeyGlow.opacity(0.4), lineWidth: 2)
                        .frame(width: 80, height: 80)

                    Text(brain.parentAvatarEmoji)
                        .font(.system(size: 42))
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                    ForEach(emojiGrid, id: \.self) { emoji in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                brain.setParentAvatar(emoji)
                            }
                        } label: {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(
                                            brain.parentAvatarEmoji == emoji
                                            ? NestPalette.honeyGlow.opacity(0.2)
                                            : NestPalette.lullabyGray.opacity(0.4)
                                        )
                                )
                                .scaleEffect(brain.parentAvatarEmoji == emoji ? 1.15 : 1.0)
                        }
                    }
                }

                Button { dismiss() } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NestPrimaryButtonStyle())

                Spacer()
            }
            .padding(20)
        }
    }
}

// MARK: - 👶 Add Child Sheet

struct AddChildNestSheet: View {

    @ObservedObject var brain: FamilyNestBrain
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "👶"
    @State private var ageGroup: AgeNestGroup = .hatchling0to3

    private let childEmojis = ["👶", "🧒", "👧", "👦", "🐣", "🦁", "🐰", "🌟"]

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("New Little One")
                            .font(NestTypography.guardianHeadline)
                            .foregroundColor(NestPalette.parentVoice)

                        Spacer()

                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(NestPalette.drowsyHint)
                        }
                    }

                    // Emoji picker
                    HStack(spacing: 10) {
                        ForEach(childEmojis, id: \.self) { e in
                            Button {
                                withAnimation(.spring(response: 0.25)) { emoji = e }
                            } label: {
                                Text(e)
                                    .font(.system(size: 26))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(
                                                emoji == e
                                                ? NestPalette.honeyGlow.opacity(0.35)
                                                : NestPalette.lullabyGray.opacity(0.4)
                                            )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                emoji == e ? NestPalette.honeyGlow : Color.clear,
                                                lineWidth: emoji == e ? 2.5 : 0
                                            )
                                    )
                                    .scaleEffect(emoji == e ? 1.1 : 1.0)
                            }
                        }
                    }

                    // Name field
                    TextField("", text: $name)
                        .placeholder(when: name.isEmpty) {
                            Text("Name (optional)")
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

                    // Age group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age Group")
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(NestPalette.tenderWhisper)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AgeNestGroup.allCases) { group in
                                    Button {
                                        withAnimation(.spring(response: 0.25)) { ageGroup = group }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(group.iconSymbol)
                                                .font(.system(size: 20))
                                            Text(group.shortLabel)
                                                .font(NestTypography.lullabyBody)
                                                .foregroundColor(
                                                    ageGroup == group
                                                    ? NestPalette.midnightNest
                                                    : NestPalette.tenderWhisper
                                                )
                                        }
                                        .frame(width: 56, height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(
                                                    ageGroup == group
                                                    ? NestPalette.honeyGlow
                                                    : NestPalette.sleepyCharcoal
                                                )
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        brain.addChild(name: name, emoji: emoji, ageGroup: ageGroup)
                        dismiss()
                    } label: {
                        Text("Add to Family")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NestPrimaryButtonStyle())
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - ✏️ Edit Child Sheet

struct EditChildNestSheet: View {

    let profile: LittleOneProfile
    @ObservedObject var brain: FamilyNestBrain
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = "👶"
    @State private var ageGroup: AgeNestGroup = .hatchling0to3

    private let childEmojis = ["👶", "🧒", "👧", "👦", "🐣", "🦁", "🐰", "🌟"]

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Edit Profile")
                            .font(NestTypography.guardianHeadline)
                            .foregroundColor(NestPalette.parentVoice)

                        Spacer()

                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(NestPalette.drowsyHint)
                        }
                    }

                    HStack(spacing: 10) {
                        ForEach(childEmojis, id: \.self) { e in
                            Button {
                                withAnimation(.spring(response: 0.25)) { emoji = e }
                            } label: {
                                Text(e)
                                    .font(.system(size: 26))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(
                                                emoji == e
                                                ? NestPalette.honeyGlow.opacity(0.35)
                                                : NestPalette.lullabyGray.opacity(0.4)
                                            )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                emoji == e ? NestPalette.honeyGlow : Color.clear,
                                                lineWidth: emoji == e ? 2.5 : 0
                                            )
                                    )
                                    .scaleEffect(emoji == e ? 1.1 : 1.0)
                            }
                        }
                    }

                    TextField("", text: $name)
                        .placeholder(when: name.isEmpty) {
                            Text("Name")
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

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AgeNestGroup.allCases) { group in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { ageGroup = group }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(group.iconSymbol)
                                            .font(.system(size: 20))
                                        Text(group.shortLabel)
                                            .font(NestTypography.lullabyBody)
                                            .foregroundColor(
                                                ageGroup == group
                                                ? NestPalette.midnightNest
                                                : NestPalette.tenderWhisper
                                            )
                                    }
                                    .frame(width: 56, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                ageGroup == group
                                                ? NestPalette.honeyGlow
                                                : NestPalette.sleepyCharcoal
                                            )
                                    )
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            brain.updateChild(
                                id: profile.id,
                                name: name,
                                emoji: emoji,
                                ageGroup: ageGroup
                            )
                            dismiss()
                        } label: {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NestPrimaryButtonStyle())
                    }

                    Button(role: .destructive) {
                        brain.removeChild(id: profile.id)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove Profile")
                        }
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.gentleBlush)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            name = profile.petName
            emoji = profile.avatarEmoji
            ageGroup = profile.ageNestGroup
        }
    }
}

// MARK: - 📊 Lifetime Stats Sheet

struct LifetimeStatsNestSheet: View {

    @EnvironmentObject var nestMemory: NestMemory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("Lifetime Statistics")
                            .font(NestTypography.cradleTitle)
                            .foregroundColor(NestPalette.parentVoice)

                        Spacer()

                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(NestPalette.drowsyHint)
                        }
                    }

                    let gp = nestMemory.guardianProgress

                    // Big numbers
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        lifetimeStatBox(
                            value: "\(gp.totalStardust)",
                            label: "Total Stardust",
                            emoji: "✦",
                            color: NestPalette.stardustReward
                        )
                        lifetimeStatBox(
                            value: "\(gp.completedDaysCount)",
                            label: "Active Days",
                            emoji: "📅",
                            color: NestPalette.honeyGlow
                        )
                        lifetimeStatBox(
                            value: "\(gp.longestStreak)",
                            label: "Best Streak",
                            emoji: "⭐️",
                            color: NestPalette.sunriseKiss
                        )
                        lifetimeStatBox(
                            value: "\(gp.earnedBadges.count)/\(NestBadgeCatalog.allBadges.count)",
                            label: "Badges Earned",
                            emoji: "🏅",
                            color: NestPalette.crownShimmer
                        )
                        lifetimeStatBox(
                            value: "\(nestMemory.profiles.count)",
                            label: "Profiles",
                            emoji: "👶",
                            color: NestPalette.calmBreath
                        )
                        lifetimeStatBox(
                            value: "Lv.\(gp.guardianLevel.rawValue)",
                            label: gp.guardianLevel.displayTitle,
                            emoji: gp.guardianLevel.emoji,
                            color: NestPalette.honeyGlow
                        )
                    }

                    // Badges earned list
                    if !gp.earnedBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Earned Badges")
                                .font(NestTypography.guardianHeadline)
                                .foregroundColor(NestPalette.parentVoice)

                            ForEach(gp.earnedBadges, id: \.id) { badge in
                                HStack(spacing: 12) {
                                    Text(badge.emoji)
                                        .font(.system(size: 28))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(badge.title)
                                            .font(NestTypography.sproutLabel)
                                            .foregroundColor(NestPalette.parentVoice)

                                        Text(badge.description)
                                            .font(NestTypography.lullabyBody)
                                            .foregroundColor(NestPalette.tenderWhisper)
                                    }

                                    Spacer()
                                }
                                .nestCard()
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
    }

    private func lifetimeStatBox(
        value: String,
        label: String,
        emoji: String,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 24))

            Text(value)
                .font(NestTypography.guardianHeadline)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.tenderWhisper)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                .fill(NestPalette.sleepyCharcoal)
                .overlay(
                    RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
