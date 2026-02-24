// GrowthGardenBrain.swift
// с17 — Daily Routine Without Stress
// Growth Garden — ViewModel (logic separated from View)

import SwiftUI
import Combine

// MARK: - 🧠 Growth Garden Brain — Insights ViewModel

final class GrowthGardenBrain: ObservableObject {

    // MARK: – Published State

    @Published var daySummary: DaySummaryNest?
    @Published var weeklySummary: WeeklySummaryNest?
    @Published var activitySlices: [DonutSlice] = []
    @Published var activityLegend: [ActivityLegendItem] = []
    @Published var insightCards: [InsightNestCard] = []
    @Published var totalBlocksForPeriod: Int = 0

    // MARK: – Private

    private var nestMemory: NestMemory?

    // MARK: – Color Map for Block Kinds

    private let kindColorMap: [BlockKind: Color] = [
        .dreamTime:    NestPalette.driftingCloud,
        .feedingNest:  NestPalette.honeyGlow,
        .freshAirWalk: NestPalette.calmBreath,
        .playGarden:   NestPalette.playfulSunbeam,
        .splashTime:   NestPalette.sunriseKiss,
        .freeSpirit:   NestPalette.tenderWhisper,
        .familyRitual: NestPalette.heartbeatStreak
    ]

    // MARK: - 🔗 Memory Binding

    func attachMemory(_ memory: NestMemory) {
        self.nestMemory = memory
    }

    // MARK: - 🔄 Refresh All Data

    func refresh() {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId else {
            clearAll()
            return
        }

        // Recompute stats from actual day data (fixes corrupted counts)
        memory.recomputeGuardianProgress()

        // Day summary
        let todayKey = NestDateHelper.todayKey()
        if let todayCradle = memory.loadDayCradle(profileId: profileId, dateKey: todayKey) {
            daySummary = memory.buildDaySummary(for: todayCradle)
        } else {
            daySummary = nil
        }

        // Weekly summary
        weeklySummary = memory.buildWeeklySummary(profileId: profileId)

        // Build donut + legend from today by default
        let blocks = collectBlocksForDonut(profileId: profileId)
        buildDonutSlices(from: blocks)
        buildActivityLegend(from: blocks)

        // Insight cards
        buildInsightCards(profileId: profileId)
    }

    private func clearAll() {
        daySummary = nil
        weeklySummary = nil
        activitySlices = []
        activityLegend = []
        insightCards = []
        totalBlocksForPeriod = 0
    }

    // MARK: - 🍩 Donut Chart

    private func collectBlocksForDonut(profileId: UUID) -> [CradleBlock] {
        guard let memory = nestMemory else { return [] }

        // Use last 7 days for richer data
        let cradles = memory.loadRecentCradles(profileId: profileId, days: 7)
        let allBlocks = cradles.flatMap { $0.blocks }
        return allBlocks
    }

    private func buildDonutSlices(from blocks: [CradleBlock]) {
        totalBlocksForPeriod = blocks.count
        guard !blocks.isEmpty else {
            activitySlices = []
            return
        }

        // Count by kind
        let grouped = Dictionary(grouping: blocks, by: { $0.blockKind })
        let sorted = grouped
            .map { (kind: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        let total = CGFloat(blocks.count)
        var currentAngle: CGFloat = 0
        var slices: [DonutSlice] = []

        for item in sorted {
            let fraction = CGFloat(item.count) / total
            let endAngle = currentAngle + fraction
            let color = kindColorMap[item.kind] ?? NestPalette.drowsyHint

            slices.append(DonutSlice(
                startAngle: currentAngle,
                endAngle: endAngle,
                color: color,
                kind: item.kind
            ))

            currentAngle = endAngle
        }

        activitySlices = slices
    }

    private func buildActivityLegend(from blocks: [CradleBlock]) {
        guard !blocks.isEmpty else {
            activityLegend = []
            return
        }

        let grouped = Dictionary(grouping: blocks, by: { $0.blockKind })
        let sorted = grouped
            .map { (kind: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        activityLegend = sorted.map { item in
            ActivityLegendItem(
                kind: item.kind,
                color: kindColorMap[item.kind] ?? NestPalette.drowsyHint,
                count: item.count
            )
        }
    }

    // MARK: - 💡 Insight Cards Generation

    private func buildInsightCards(profileId: UUID) {
        guard let memory = nestMemory else {
            insightCards = []
            return
        }

        var cards: [InsightNestCard] = []
        let cradles = memory.loadRecentCradles(profileId: profileId, days: 7)
        let allBlocks = cradles.flatMap { $0.blocks }

        guard !allBlocks.isEmpty else {
            insightCards = []
            return
        }

        // Insight 1: Most stable block type
        let doneBlocks = allBlocks.filter { $0.completionMark == .done && $0.moveCount == 0 }
        if let stableKind = mostFrequent(doneBlocks.map { $0.blockKind }) {
            cards.append(InsightNestCard(
                title: "Rock Solid \(stableKind.emoji)",
                message: "\(stableKind.displayTitle) blocks are your most consistent — they rarely move or get skipped.",
                icon: "lock.shield.fill",
                accentColor: NestPalette.calmBreath
            ))
        }

        // Insight 2: Most moved block type
        let movedBlocks = allBlocks.filter { $0.completionMark == .moved || $0.moveCount > 0 }
        if let movedKind = mostFrequent(movedBlocks.map { $0.blockKind }) {
            cards.append(InsightNestCard(
                title: "Drifting \(movedKind.emoji)",
                message: "\(movedKind.displayTitle) tends to shift the most. Consider making the time window more flexible.",
                icon: "arrow.left.arrow.right",
                accentColor: NestPalette.driftingCloud
            ))
        }

        // Insight 3: Completion trend
        let dailySummaries = cradles.map { memory.buildDaySummary(for: $0) }
        if dailySummaries.count >= 3 {
            let recentAvg = dailySummaries.prefix(3)
                .map { $0.completionPercent }
                .reduce(0, +) / 3.0

            let olderAvg = dailySummaries.dropFirst(3)
                .map { $0.completionPercent }
                .reduce(0, +) / max(Double(dailySummaries.count - 3), 1)

            if recentAvg > olderAvg + 10 {
                cards.append(InsightNestCard(
                    title: "Rising Tide 📈",
                    message: "Your completion rate has been climbing! The routine is settling in nicely.",
                    icon: "chart.line.uptrend.xyaxis",
                    accentColor: NestPalette.sproutSparkle
                ))
            } else if recentAvg < olderAvg - 10 {
                cards.append(InsightNestCard(
                    title: "Gentle Dip 📉",
                    message: "Completion has softened a bit. No pressure — adjust blocks to match your real flow.",
                    icon: "chart.line.downtrend.xyaxis",
                    accentColor: NestPalette.gentleBlush
                ))
            }
        }

        // Insight 4: Skipped pattern
        let skippedBlocks = allBlocks.filter { $0.completionMark == .skipped }
        if let skippedKind = mostFrequent(skippedBlocks.map { $0.blockKind }),
           skippedBlocks.count >= 3 {
            cards.append(InsightNestCard(
                title: "Often Skipped \(skippedKind.emoji)",
                message: "\(skippedKind.displayTitle) gets skipped frequently. Maybe it needs a different time slot?",
                icon: "xmark.circle",
                accentColor: NestPalette.gentleBlush
            ))
        }

        // Insight 5: Streak celebration
        let gp = memory.guardianProgress
        if gp.currentStreak >= 3 {
            cards.append(InsightNestCard(
                title: "Streak Power 🔥",
                message: "\(gp.currentStreak) days in a row! Consistency builds trust in the routine.",
                icon: "flame.fill",
                accentColor: NestPalette.heartbeatStreak
            ))
        }

        // Insight 6: XP milestone approaching
        let toNext = gp.stardustToNextLevel
        if toNext < 100 && toNext > 0 {
            cards.append(InsightNestCard(
                title: "Level Up Soon ✨",
                message: "Only \(toNext) stardust away from \(gp.guardianLevel.displayTitle) → next level!",
                icon: "arrow.up.circle.fill",
                accentColor: NestPalette.stardustReward
            ))
        }

        // Insight 7: Morning vs afternoon pattern
        let morningDone = allBlocks.filter { $0.completionMark == .done && $0.startFeather < 720 }
        let afternoonDone = allBlocks.filter { $0.completionMark == .done && $0.startFeather >= 720 }
        if morningDone.count > afternoonDone.count + 3 {
            cards.append(InsightNestCard(
                title: "Morning Champion 🌅",
                message: "You're more productive before noon. Front-load important blocks for best results.",
                icon: "sunrise.fill",
                accentColor: NestPalette.sunriseKiss
            ))
        } else if afternoonDone.count > morningDone.count + 3 {
            cards.append(InsightNestCard(
                title: "Afternoon Flow 🌇",
                message: "Afternoons are your strong suit. Lean into that natural rhythm.",
                icon: "sunset.fill",
                accentColor: NestPalette.playfulSunbeam
            ))
        }

        // Cap at 4 cards maximum to keep it clean
        insightCards = Array(cards.prefix(4))
    }

    // MARK: - 🔧 Helpers

    private func mostFrequent(_ kinds: [BlockKind]) -> BlockKind? {
        guard !kinds.isEmpty else { return nil }
        let counts = Dictionary(grouping: kinds, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
