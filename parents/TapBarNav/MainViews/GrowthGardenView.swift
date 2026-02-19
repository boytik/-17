// GrowthGardenView.swift
// с17 — Daily Routine Without Stress
// Growth Garden — Insights & Stats View (ViewModel in GrowthGardenBrain.swift)

import SwiftUI

// MARK: - 🌱 Growth Garden View — Insights Tab

struct GrowthGardenView: View {

    @EnvironmentObject var nestMemory: NestMemory
    @StateObject private var brain = GrowthGardenBrain()

    @State private var selectedPeriod: GardenPeriod = .today
    @State private var showBadgeDetail: NestBadge? = nil

    var body: some View {
        ZStack {
            StarryNestBackground(particleCount: 20, showAura: true)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    gardenHeader
                        .padding(.top, 12)

                    // Period switcher
                    periodSwitcher
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Guardian level card
                    guardianLevelCard
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Stats overview
                    if selectedPeriod == .today {
                        dailyStatsSection
                            .padding(.horizontal, NestDimensions.nestPadding)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    } else {
                        weeklyStatsSection
                            .padding(.horizontal, NestDimensions.nestPadding)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }

                    // Activity donut chart
                    activityDonutSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Streak & rhythm section
                    streakRhythmSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Badges showcase
                    badgesShowcase
                        .padding(.horizontal, NestDimensions.nestPadding)

                    // Insights cards
                    insightCardsSection
                        .padding(.horizontal, NestDimensions.nestPadding)

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(item: $showBadgeDetail) { badge in
            BadgeDetailNestSheet(badge: badge)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            brain.attachMemory(nestMemory)
            brain.refresh()
        }
        .onChange(of: selectedPeriod) { _ in
            brain.refresh()
        }
    }

    // MARK: – Header

    private var gardenHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Growth Garden")
                    .font(NestTypography.cradleTitle)
                    .foregroundColor(NestPalette.parentVoice)

                Text("See how your rhythm evolves")
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.tenderWhisper)
            }

            Spacer()

            // Stardust counter
            HStack(spacing: 4) {
                Text("✦")
                    .font(.system(size: 14))
                    .foregroundColor(NestPalette.stardustReward)

                Text("\(nestMemory.guardianProgress.totalStardust)")
                    .font(NestTypography.sproutLabel)
                    .foregroundColor(NestPalette.sunriseKiss)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(NestPalette.sleepyCharcoal)
                    .overlay(
                        Capsule()
                            .stroke(NestPalette.honeyGlow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, NestDimensions.nestPadding)
    }

    // MARK: – Period Switcher

    private var periodSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(GardenPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.displayLabel)
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(
                            selectedPeriod == period
                            ? NestPalette.midnightNest
                            : NestPalette.tenderWhisper
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selectedPeriod == period
                                    ? NestPalette.honeyGlow
                                    : Color.clear
                                )
                        )
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(NestPalette.sleepyCharcoal)
        )
    }

    // MARK: – Guardian Level Card

    private var guardianLevelCard: some View {
        let gp = nestMemory.guardianProgress
        let level = gp.guardianLevel

        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                // Level circle
                ZStack {
                    Circle()
                        .fill(NestPalette.honeyGlow.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: gp.levelWarmth)
                        .stroke(
                            NestGradients.sunrisePath,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Text(level.emoji)
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayTitle)
                        .font(NestTypography.guardianHeadline)
                        .foregroundColor(NestPalette.parentVoice)

                    Text("\(gp.stardustToNextLevel) ✦ to next level")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)

                    // XP progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(NestPalette.lullabyGray)
                                .frame(height: 6)

                            Capsule()
                                .fill(NestGradients.sunrisePath)
                                .frame(width: geo.size.width * gp.levelWarmth, height: 6)
                                .animation(.easeOut(duration: 0.8), value: gp.levelWarmth)
                        }
                    }
                    .frame(height: 6)
                }

                Spacer()
            }
        }
        .nestCard(elevated: true)
    }

    // MARK: – Daily Stats

    private var dailyStatsSection: some View {
        let summary = brain.daySummary

        return VStack(alignment: .leading, spacing: 12) {
            Text("Today's Summary")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            HStack(spacing: 10) {
                statMiniCard(
                    value: "\(summary?.doneCount ?? 0)",
                    label: "Done",
                    color: NestPalette.calmBreath,
                    icon: "checkmark.circle.fill"
                )
                statMiniCard(
                    value: "\(summary?.movedCount ?? 0)",
                    label: "Moved",
                    color: NestPalette.driftingCloud,
                    icon: "arrow.right.circle.fill"
                )
                statMiniCard(
                    value: "\(summary?.skippedCount ?? 0)",
                    label: "Skipped",
                    color: NestPalette.gentleBlush,
                    icon: "xmark.circle"
                )
                statMiniCard(
                    value: "+\(summary?.totalXPEarned ?? 0)✦",
                    label: "Earned",
                    color: NestPalette.stardustReward,
                    icon: "star.fill"
                )
            }

            // Completion percentage bar
            completionBarView(
                percent: summary?.completionPercent ?? 0,
                label: "Day completion"
            )
        }
    }

    // MARK: – Weekly Stats

    private var weeklyStatsSection: some View {
        let weekly = brain.weeklySummary

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(NestTypography.guardianHeadline)
                    .foregroundColor(NestPalette.parentVoice)

                Spacer()

                if let label = weekly?.weekLabel {
                    Text(label)
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.drowsyHint)
                }
            }

            // Weekly bar chart
            if let weekly = weekly, !weekly.dailySummaries.isEmpty {
                weeklyBarChart(summaries: weekly.dailySummaries)
            }

            HStack(spacing: 10) {
                statMiniCard(
                    value: String(format: "%.0f%%", weekly?.averageCompletion ?? 0),
                    label: "Avg",
                    color: NestPalette.honeyGlow,
                    icon: "chart.bar.fill"
                )
                statMiniCard(
                    value: "\(weekly?.streakDays ?? 0)d",
                    label: "Streak",
                    color: NestPalette.heartbeatStreak,
                    icon: "flame.fill"
                )
                statMiniCard(
                    value: "+\(weekly?.totalXP ?? 0)✦",
                    label: "Earned",
                    color: NestPalette.stardustReward,
                    icon: "star.fill"
                )
            }

            completionBarView(
                percent: weekly?.averageCompletion ?? 0,
                label: "Weekly average"
            )
        }
    }

    // MARK: – Weekly Bar Chart

    private func weeklyBarChart(summaries: [DaySummaryNest]) -> some View {
        let maxBlocks = summaries.map { $0.totalBlocks }.max() ?? 1

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(summaries.reversed(), id: \.dateKey) { day in
                VStack(spacing: 4) {
                    // Bar
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NestPalette.lullabyGray)
                            .frame(height: 80)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                day.completionPercent >= 80
                                ? NestPalette.honeyGlow
                                : day.completionPercent >= 50
                                    ? NestPalette.driftingCloud
                                    : NestPalette.lullabyGray.opacity(0.8)
                            )
                            .frame(
                                height: maxBlocks > 0
                                    ? CGFloat(day.doneCount) / CGFloat(maxBlocks) * 80
                                    : 0
                            )
                            .animation(.easeOut(duration: 0.5), value: day.doneCount)
                    }
                    .frame(height: 80)

                    // Day label
                    Text(shortDayLabel(day.dateKey))
                        .font(NestTypography.tinyFootprint)
                        .foregroundColor(
                            NestDateHelper.isToday(day.dateKey)
                            ? NestPalette.honeyGlow
                            : NestPalette.drowsyHint
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                .fill(NestPalette.sleepyCharcoal)
        )
    }

    private func shortDayLabel(_ dateKey: String) -> String {
        guard let date = NestDateHelper.date(from: dateKey) else { return "?" }
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(2))
    }

    // MARK: – Activity Donut Section

    private var activityDonutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Breakdown")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            HStack(spacing: 20) {
                // Donut
                ZStack {
                    ForEach(Array(brain.activitySlices.enumerated()), id: \.offset) { index, slice in
                        Circle()
                            .trim(from: slice.startAngle, to: slice.endAngle)
                            .stroke(
                                slice.color,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                    }

                    if brain.activitySlices.isEmpty {
                        Circle()
                            .stroke(NestPalette.lullabyGray, lineWidth: 14)
                            .frame(width: 100, height: 100)
                    }

                    VStack(spacing: 0) {
                        Text("\(brain.totalBlocksForPeriod)")
                            .font(NestTypography.guardianHeadline)
                            .foregroundColor(NestPalette.parentVoice)

                        Text("blocks")
                            .font(NestTypography.tinyFootprint)
                            .foregroundColor(NestPalette.drowsyHint)
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(brain.activityLegend, id: \.kind) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)

                            Text(item.kind.displayTitle)
                                .font(NestTypography.whisperCaption)
                                .foregroundColor(NestPalette.tenderWhisper)

                            Spacer()

                            Text("\(item.count)")
                                .font(NestTypography.tinyFootprint)
                                .foregroundColor(NestPalette.drowsyHint)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .fill(NestPalette.sleepyCharcoal)
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .stroke(NestPalette.dreamlineDivider.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: – Streak & Rhythm

    private var streakRhythmSection: some View {
        let gp = nestMemory.guardianProgress

        return VStack(alignment: .leading, spacing: 12) {
            Text("Rhythm & Streaks")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            HStack(spacing: 12) {
                // Current streak
                VStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 28))

                    Text("\(gp.currentStreak)")
                        .font(NestTypography.milestoneNumber)
                        .foregroundColor(NestPalette.heartbeatStreak)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("Current\nStreak")
                        .font(NestTypography.tinyFootprint)
                        .foregroundColor(NestPalette.tenderWhisper)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                        .fill(NestPalette.sleepyCharcoal)
                )

                // Best streak
                VStack(spacing: 8) {
                    Text("⭐️")
                        .font(.system(size: 28))

                    Text("\(gp.longestStreak)")
                        .font(NestTypography.milestoneNumber)
                        .foregroundColor(NestPalette.honeyGlow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("Best\nStreak")
                        .font(NestTypography.tinyFootprint)
                        .foregroundColor(NestPalette.tenderWhisper)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                        .fill(NestPalette.sleepyCharcoal)
                )

                // Total days
                VStack(spacing: 8) {
                    Text("📅")
                        .font(.system(size: 28))

                    Text("\(gp.completedDaysCount)")
                        .font(NestTypography.milestoneNumber)
                        .foregroundColor(NestPalette.sunriseKiss)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("Active\nDays")
                        .font(NestTypography.tinyFootprint)
                        .foregroundColor(NestPalette.tenderWhisper)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                        .fill(NestPalette.sleepyCharcoal)
                )
            }
        }
    }

    // MARK: – Badges Showcase

    private var badgesShowcase: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges")
                    .font(NestTypography.guardianHeadline)
                    .foregroundColor(NestPalette.parentVoice)

                Spacer()

                let earned = nestMemory.guardianProgress.earnedBadges.count
                let total = NestBadgeCatalog.allBadges.count
                Text("\(earned)/\(total)")
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.tenderWhisper)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NestBadgeCatalog.allBadges, id: \.id) { badge in
                        let isUnlocked = nestMemory.guardianProgress.earnedBadges
                            .contains { $0.id == badge.id }

                        Button {
                            showBadgeDetail = badge
                        } label: {
                            badgeCell(badge: badge, unlocked: isUnlocked)
                        }
                    }
                }
            }
        }
    }

    private func badgeCell(badge: NestBadge, unlocked: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        unlocked
                        ? NestPalette.honeyGlow.opacity(0.15)
                        : NestPalette.lullabyGray.opacity(0.5)
                    )
                    .frame(width: 56, height: 56)

                if unlocked {
                    Circle()
                        .stroke(NestPalette.honeyGlow.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                }

                Text(unlocked ? badge.emoji : "🔒")
                    .font(.system(size: 24))
                    .opacity(unlocked ? 1.0 : 0.5)
            }

            Text(badge.title)
                .font(NestTypography.tinyFootprint)
                .foregroundColor(
                    unlocked ? NestPalette.tenderWhisper : NestPalette.drowsyHint
                )
                .lineLimit(1)
        }
        .frame(width: 72)
    }

    // MARK: – Insight Cards

    private var insightCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            if brain.insightCards.isEmpty {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(NestPalette.honeyGlow)

                    Text("Complete a few days to unlock insights")
                        .font(NestTypography.lullabyBody)
                        .foregroundColor(NestPalette.tenderWhisper)
                }
                .nestCard()
            } else {
                ForEach(brain.insightCards, id: \.title) { card in
                    insightCardView(card)
                }
            }
        }
    }

    private func insightCardView(_ card: InsightNestCard) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(card.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: card.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(card.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(NestTypography.sproutLabel)
                    .foregroundColor(NestPalette.parentVoice)

                Text(card.message)
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.tenderWhisper)
                    .lineLimit(3)
            }

            Spacer()
        }
        .nestCard()
    }

    // MARK: – Reusable Components

    private func statMiniCard(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(value)
                .font(NestTypography.sproutLabel)
                .foregroundColor(NestPalette.parentVoice)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(NestTypography.tinyFootprint)
                .foregroundColor(NestPalette.drowsyHint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                .fill(NestPalette.sleepyCharcoal)
        )
    }

    private func completionBarView(percent: Double, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.tenderWhisper)

                Spacer()

                Text(String(format: "%.0f%%", percent))
                    .font(NestTypography.sproutLabel)
                    .foregroundColor(NestPalette.honeyGlow)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NestPalette.lullabyGray)
                        .frame(height: 8)

                    Capsule()
                        .fill(NestGradients.sunrisePath)
                        .frame(width: geo.size.width * min(percent / 100, 1.0), height: 8)
                        .animation(.easeOut(duration: 0.6), value: percent)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                .fill(NestPalette.sleepyCharcoal.opacity(0.5))
        )
    }
}




