// NestMemory.swift
// с17 — Daily Routine Without Stress
// Local persistence — JSON files + UserDefaults, no Core Data

import Foundation
import Combine
// MARK: - 🧠 Nest Memory — Central Storage Manager

/// The family memory chest — stores everything locally as JSON files.
/// No Core Data, no cloud, no accounts. Pure offline simplicity.
final class NestMemory: ObservableObject {

    static let shared = NestMemory()

    // MARK: – Published State

    @Published var settings: NestSettings
    @Published var profiles: [LittleOneProfile]
    @Published var guardianProgress: GuardianProgress
    @Published var todayCradle: DayCradle?

    // MARK: – Private Keys

    private enum DrawerKey {
        static let settings       = "nest_settings_chest"
        static let profiles       = "nest_profiles_chest"
        static let guardian        = "nest_guardian_chest"
        static let dayPrefix      = "nest_day_"           // + profileId_dateKey
        static let templatePrefix = "nest_template_"      // + id
        static let onboardDone    = "nest_onboard_done"
    }

    // MARK: – File Manager Paths

    private let nestFolder: URL

    // MARK: – Init

    private init() {
        // Create app's document subfolder
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.nestFolder = docs.appendingPathComponent("NestMemory", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: nestFolder,
            withIntermediateDirectories: true
        )

        // Load persisted state
        self.settings = Self.loadFromDefaults(key: DrawerKey.settings) ?? NestSettings()
        self.profiles = Self.loadFromDefaults(key: DrawerKey.profiles) ?? []
        self.guardianProgress = Self.loadFromDefaults(key: DrawerKey.guardian) ?? GuardianProgress()
        self.todayCradle = nil

        // Load today's plan for active profile
        if let activeId = settings.activeProfileId {
            let todayKey = NestDateHelper.todayKey()
            self.todayCradle = loadDayCradle(profileId: activeId, dateKey: todayKey)
        }
    }

    // MARK: - 💾 Settings

    func tuckinSettings(_ updated: NestSettings) {
        settings = updated
        Self.saveToDefaults(updated, key: DrawerKey.settings)
    }

    func markOnboardingComplete() {
        var s = settings
        s.hasCompletedOnboarding = true
        tuckinSettings(s)
        UserDefaults.standard.set(true, forKey: DrawerKey.onboardDone)
    }

    var hasCompletedOnboarding: Bool {
        settings.hasCompletedOnboarding ||
        UserDefaults.standard.bool(forKey: DrawerKey.onboardDone)
    }

    // MARK: - 👶 Profiles

    func nestNewProfile(_ profile: LittleOneProfile) {
        var list = profiles
        list.append(profile)
        profiles = list
        Self.saveToDefaults(list, key: DrawerKey.profiles)

        // Auto-activate if first profile
        if settings.activeProfileId == nil {
            var s = settings
            s.activeProfileId = profile.id
            tuckinSettings(s)
        }
    }

    func updateProfile(_ profile: LittleOneProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            Self.saveToDefaults(profiles, key: DrawerKey.profiles)
        }
    }

    func removeProfile(_ profileId: UUID) {
        let wasActive = settings.activeProfileId == profileId

        profiles.removeAll { $0.id == profileId }
        Self.saveToDefaults(profiles, key: DrawerKey.profiles)

        // Clear active if removed
        if wasActive {
            var s = settings
            s.activeProfileId = profiles.first?.id
            tuckinSettings(s)
            // Clear todayCradle when removed profile was active
            todayCradle = nil
            if let newActiveId = profiles.first?.id {
                let todayKey = NestDateHelper.todayKey()
                todayCradle = loadDayCradle(profileId: newActiveId, dateKey: todayKey)
            }
        }

        // Remove associated day files
        removeAllDays(for: profileId)
    }

    func switchActiveProfile(to profileId: UUID) {
        var s = settings
        s.activeProfileId = profileId
        tuckinSettings(s)

        // Reload today
        let todayKey = NestDateHelper.todayKey()
        todayCradle = loadDayCradle(profileId: profileId, dateKey: todayKey)
    }

    var activeProfile: LittleOneProfile? {
        guard let id = settings.activeProfileId else { return profiles.first }
        return profiles.first { $0.id == id }
    }

    // MARK: - 📅 Day Cradle (Day Plans)

    private func dayCradleKey(profileId: UUID, dateKey: String) -> String {
        "\(DrawerKey.dayPrefix)\(profileId.uuidString)_\(dateKey)"
    }

    func saveDayCradle(_ day: DayCradle) {
        let key = dayCradleKey(profileId: day.profileId, dateKey: day.dateKey)
        saveToFile(day, filename: key)

        // Update published if it's today
        if day.dateKey == NestDateHelper.todayKey() && day.profileId == settings.activeProfileId {
            todayCradle = day
        }

        // Reschedule notifications for today
        if day.dateKey == NestDateHelper.todayKey() {
            NestNotificationService.shared.rescheduleForToday(day: day, settings: settings)
        }
    }

    /// Call when app becomes active — reschedules in case day rolled over or settings changed.
    func rescheduleTodayNotificationsIfNeeded() {
        guard let day = todayCradle else { return }
        NestNotificationService.shared.rescheduleForToday(day: day, settings: settings)
    }

    func loadDayCradle(profileId: UUID, dateKey: String) -> DayCradle? {
        let key = dayCradleKey(profileId: profileId, dateKey: dateKey)
        return loadFromFile(key)
    }

    func loadOrCreateToday(profileId: UUID) -> DayCradle {
        let todayKey = NestDateHelper.todayKey()
        if let existing = loadDayCradle(profileId: profileId, dateKey: todayKey) {
            return existing
        }

        let newDay = DayCradle(dateKey: todayKey, profileId: profileId)
        saveDayCradle(newDay)
        return newDay
    }

    /// Load the last N days for insights.
    func loadRecentCradles(profileId: UUID, days: Int = 7) -> [DayCradle] {
        let calendar = Calendar.current
        var results: [DayCradle] = []

        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let key = NestDateHelper.dateKey(for: date)
            if let day = loadDayCradle(profileId: profileId, dateKey: key) {
                results.append(day)
            }
        }

        return results
    }

    /// Load all saved days for a profile (for stats recompute).
    func loadAllCradles(profileId: UUID) -> [DayCradle] {
        let prefix = "\(DrawerKey.dayPrefix)\(profileId.uuidString)"
        let cradles: [DayCradle] = loadAllFiles(withPrefix: prefix)
        return cradles.sorted { ($0.dateKey) < ($1.dateKey) }
    }

    /// Recompute guardian stats from actual day data — fixes corrupted counts.
    func recomputeGuardianProgress() {
        // Aggregate across all profiles (guardian progress is app-wide)
        let allCradles = profiles.flatMap { loadAllCradles(profileId: $0.id) }
        let todayKey = NestDateHelper.todayKey()
        let calendar = Calendar.current

        // Active days: unique dates with at least 1 block done
        let activeDateKeys = Set(allCradles
            .filter { $0.doneLullabies >= 1 }
            .map { $0.dateKey })

        // Streak days: dates with ≥50% completion, sorted
        let streakDateKeys = allCradles
            .filter { $0.totalLullabies > 0 && Double($0.doneLullabies) / Double($0.totalLullabies) >= 0.5 }
            .map { $0.dateKey }
        let sortedStreakDates = Array(Set(streakDateKeys)).sorted()

        // Current streak: consecutive days ending at today or yesterday
        var currentStreak = 0
        if let lastStreak = sortedStreakDates.last,
           let lastDate = NestDateHelper.date(from: lastStreak),
           let today = NestDateHelper.date(from: todayKey) {
            let daysSinceLast = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 999
            if daysSinceLast <= 1 {
                currentStreak = 1
                var check = lastDate
                for key in sortedStreakDates.reversed().dropFirst() {
                    guard let d = NestDateHelper.date(from: key) else { continue }
                    let diff = calendar.dateComponents([.day], from: d, to: check).day ?? 999
                    if diff == 1 {
                        currentStreak += 1
                        check = d
                    } else { break }
                }
            }
        }

        // Longest streak (guard: 1..<0 crashes with "Can't form range with end < start")
        var longestStreak = sortedStreakDates.isEmpty ? 0 : 1
        var run = 1
        if sortedStreakDates.count >= 2 {
            for i in 1..<sortedStreakDates.count {
                guard let prev = NestDateHelper.date(from: sortedStreakDates[i - 1]),
                      let curr = NestDateHelper.date(from: sortedStreakDates[i]) else { continue }
                let diff = calendar.dateComponents([.day], from: prev, to: curr).day ?? 999
                if diff == 1 {
                    run += 1
                } else {
                    longestStreak = max(longestStreak, run)
                    run = 1
                }
            }
            longestStreak = max(longestStreak, run)
        }
        longestStreak = max(longestStreak, currentStreak)

        var gp = guardianProgress
        gp.completedDaysCount = activeDateKeys.count
        gp.currentStreak = currentStreak
        gp.longestStreak = longestStreak
        gp.lastActiveDate = sortedStreakDates.last ?? activeDateKeys.sorted().last ?? ""
        guardianProgress = gp
        Self.saveToDefaults(gp, key: DrawerKey.guardian)
    }

    private func removeAllDays(for profileId: UUID) {
        let prefix = "\(DrawerKey.dayPrefix)\(profileId.uuidString)"
        removeFilesWithPrefix(prefix)
    }

    // MARK: - 🏆 Guardian Progress (Gamification)

    func awardStardust(_ xp: Int) {
        guardianProgress.totalStardust += xp
        Self.saveToDefaults(guardianProgress, key: DrawerKey.guardian)
    }

    func recordDayCompletion(dateKey: String, completionRatio: Double) {
        let today = dateKey
        var gp = guardianProgress
        let isSameDay = (gp.lastActiveDate == today)

        // Only count each day once — was incrementing on every block mark (bug)
        if !isSameDay {
            gp.completedDaysCount += 1
        }

        // Streak logic
        if completionRatio >= 0.5 {
            if gp.lastActiveDate.isEmpty {
                gp.currentStreak = 1
            } else if isSameDay {
                // Same day, just crossed 50% — ensure streak ≥ 1
                if gp.currentStreak == 0 { gp.currentStreak = 1 }
            } else if let lastDate = NestDateHelper.date(from: gp.lastActiveDate),
                      let currentDate = NestDateHelper.date(from: today) {
                let daysBetween = Calendar.current.dateComponents(
                    [.day], from: lastDate, to: currentDate
                ).day ?? 0

                if daysBetween == 1 {
                    gp.currentStreak += 1
                } else if daysBetween > 1 {
                    gp.currentStreak = 1
                }
            }

            gp.longestStreak = max(gp.longestStreak, gp.currentStreak)
        } else {
            gp.currentStreak = 0
        }

        gp.lastActiveDate = today
        guardianProgress = gp
        Self.saveToDefaults(gp, key: DrawerKey.guardian)
    }

    func unlockBadge(_ badgeId: String) {
        guard !guardianProgress.earnedBadges.contains(where: { $0.id == badgeId }) else { return }

        if var badge = NestBadgeCatalog.allBadges.first(where: { $0.id == badgeId }) {
            badge.unlockedAt = Date()
            guardianProgress.earnedBadges.append(badge)
            Self.saveToDefaults(guardianProgress, key: DrawerKey.guardian)
        }
    }

    /// Check and unlock badges based on current state.
    func evaluateBadges(day: DayCradle) {
        let gp = guardianProgress

        // First Step
        if day.doneLullabies >= 1 {
            unlockBadge("first_step")
        }

        // Golden Day
        if day.totalLullabies > 0 && day.doneLullabies == day.totalLullabies {
            unlockBadge("perfect_day")
        }

        // Early Bird
        if day.blocks.contains(where: {
            $0.completionMark == .done && $0.startFeather < 480  // before 8AM
        }) {
            unlockBadge("early_bird")
        }

        // Night Owl
        if day.blocks.contains(where: {
            $0.completionMark == .done && $0.endFeather > 1320  // after 10PM
        }) {
            unlockBadge("night_owl")
        }

        // Streak badges
        if gp.currentStreak >= 3 { unlockBadge("streak_3") }
        if gp.currentStreak >= 7 { unlockBadge("streak_7") }

        // Centurion
        let totalDone = loadAllCompletedBlocksCount()
        if totalDone >= 100 { unlockBadge("centurion") }

        // Flexible Flow
        let movedNotSkipped = day.blocks.filter { $0.completionMark == .moved }.count >= 5
            && day.blocks.filter { $0.completionMark == .skipped }.isEmpty
        if movedNotSkipped { unlockBadge("flexible") }
    }

    private func loadAllCompletedBlocksCount() -> Int {
        guard let profileId = settings.activeProfileId else { return 0 }
        let cradles = loadRecentCradles(profileId: profileId, days: 365)
        return cradles.reduce(0) { $0 + $1.doneLullabies }
    }

    // MARK: - 📋 Templates

    func saveTemplate(_ template: RoutineNestTemplate) {
        let key = "\(DrawerKey.templatePrefix)\(template.id.uuidString)"
        saveToFile(template, filename: key)
    }

    func loadAllTemplates() -> [RoutineNestTemplate] {
        let prefix = DrawerKey.templatePrefix
        return loadAllFiles(withPrefix: prefix)
    }

    /// Create a template from a day's blocks (for "Save as template").
    func createTemplateFromDay(day: DayCradle, title: String, ageGroup: AgeNestGroup) -> RoutineNestTemplate {
        let seeds = day.blocks.map { block in
            TemplateBlockSeed(
                blockKind: block.blockKind,
                startMinute: block.startFeather,
                endMinute: block.endFeather
            )
        }
        let template = RoutineNestTemplate(
            title: title,
            ageGroup: ageGroup,
            style: .calm,
            blocks: seeds
        )
        saveTemplate(template)
        return template
    }

    /// Generate CradleBlocks from a template for a given date.
    func applyTemplate(_ template: RoutineNestTemplate, profileId: UUID, dateKey: String) -> DayCradle {
        let blocks = template.blocks.map { seed in
            CradleBlock(
                blockKind: seed.blockKind,
                startFeather: seed.startMinute,
                endFeather: seed.endMinute
            )
        }

        let day = DayCradle(
            dateKey: dateKey,
            profileId: profileId,
            blocks: blocks
        )

        saveDayCradle(day)
        return day
    }

    // MARK: - 📊 Stats Helpers

    func buildDaySummary(for day: DayCradle) -> DaySummaryNest {
        let doneBlocks = day.blocks.filter { $0.completionMark == .done }
        let movedBlocks = day.blocks.filter { $0.completionMark == .moved }
        let skippedBlocks = day.blocks.filter { $0.completionMark == .skipped }
        let pendingBlocks = day.blocks.filter { $0.completionMark == .pending }

        let xp = doneBlocks.reduce(0) { $0 + $1.blockKind.sproutXP }

        // Most moved kind
        let movedKinds = movedBlocks.map { $0.blockKind }
        let mostMoved = mostFrequent(in: movedKinds)

        // Most stable kind (done and never moved)
        let stableKinds = doneBlocks.filter { $0.moveCount == 0 }.map { $0.blockKind }
        let mostStable = mostFrequent(in: stableKinds)

        return DaySummaryNest(
            dateKey: day.dateKey,
            totalBlocks: day.totalLullabies,
            doneCount: doneBlocks.count,
            movedCount: movedBlocks.count,
            skippedCount: skippedBlocks.count,
            pendingCount: pendingBlocks.count,
            totalXPEarned: xp,
            mostMovedKind: mostMoved,
            mostStableKind: mostStable
        )
    }

    func buildWeeklySummary(profileId: UUID) -> WeeklySummaryNest {
        let cradles = loadRecentCradles(profileId: profileId, days: 7)
        let dailies = cradles.map { buildDaySummary(for: $0) }

        let avgCompletion: Double
        if dailies.isEmpty {
            avgCompletion = 0
        } else {
            avgCompletion = dailies.reduce(0.0) { $0 + $1.completionPercent } / Double(dailies.count)
        }

        let best = dailies.max(by: { $0.completionPercent < $1.completionPercent })?.dateKey
        let worst = dailies.filter { $0.totalBlocks > 0 }
            .min(by: { $0.completionPercent < $1.completionPercent })?.dateKey

        let totalXP = dailies.reduce(0) { $0 + $1.totalXPEarned }

        // Build week label
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: today)!
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let weekLabel = "\(f.string(from: weekAgo)) – \(f.string(from: today))"

        return WeeklySummaryNest(
            weekLabel: weekLabel,
            dailySummaries: dailies,
            averageCompletion: avgCompletion,
            bestDay: best,
            worstDay: worst,
            streakDays: guardianProgress.currentStreak,
            totalXP: totalXP
        )
    }

    private func mostFrequent(in kinds: [BlockKind]) -> BlockKind? {
        guard !kinds.isEmpty else { return nil }
        let counts = Dictionary(grouping: kinds, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - 🗑 Reset

    func resetAllNestData() {
        profiles = []
        guardianProgress = GuardianProgress()
        settings = NestSettings()
        todayCradle = nil

        // Clear UserDefaults
        for key in [DrawerKey.settings, DrawerKey.profiles, DrawerKey.guardian, DrawerKey.onboardDone] {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Clear files
        try? FileManager.default.removeItem(at: nestFolder)
        try? FileManager.default.createDirectory(at: nestFolder, withIntermediateDirectories: true)
    }

    // MARK: - 🔧 Generic Persistence — UserDefaults (small data)

    private static func saveToDefaults<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadFromDefaults<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - 🔧 Generic Persistence — JSON Files (large / many records)

    private func fileURL(for filename: String) -> URL {
        nestFolder.appendingPathComponent("\(filename).json")
    }

    private func saveToFile<T: Encodable>(_ value: T, filename: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: fileURL(for: filename), options: .atomic)
        } catch {
            print("🪺 NestMemory write error [\(filename)]: \(error.localizedDescription)")
        }
    }

    private func loadFromFile<T: Decodable>(_ filename: String) -> T? {
        let url = fileURL(for: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("🪺 NestMemory read error [\(filename)]: \(error.localizedDescription)")
            return nil
        }
    }

    private func loadAllFiles<T: Decodable>(withPrefix prefix: String) -> [T] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: nestFolder, includingPropertiesForKeys: nil
        ) else { return [] }

        return contents
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .compactMap { url -> T? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(T.self, from: data)
            }
    }

    private func removeFilesWithPrefix(_ prefix: String) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: nestFolder, includingPropertiesForKeys: nil
        ) else { return }

        for url in contents where url.lastPathComponent.hasPrefix(prefix) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - 🌱 Default Templates Factory

/// Generates built-in templates per age group.
enum NestTemplateSeedlings {

    static func defaultTemplates(for group: AgeNestGroup) -> [RoutineNestTemplate] {
        switch group {
        case .hatchling0to3:
            return [
                calmTemplate(group: group, blocks: [
                    .init(blockKind: .dreamTime,    startMinute: 0,    endMinute: 420),
                    .init(blockKind: .feedingNest,   startMinute: 420,  endMinute: 450),
                    .init(blockKind: .dreamTime,    startMinute: 480,  endMinute: 600),
                    .init(blockKind: .feedingNest,   startMinute: 600,  endMinute: 630),
                    .init(blockKind: .freeSpirit,   startMinute: 630,  endMinute: 720),
                    .init(blockKind: .feedingNest,   startMinute: 720,  endMinute: 750),
                    .init(blockKind: .dreamTime,    startMinute: 750,  endMinute: 900),
                    .init(blockKind: .feedingNest,   startMinute: 900,  endMinute: 930),
                    .init(blockKind: .splashTime,   startMinute: 1140, endMinute: 1170),
                    .init(blockKind: .dreamTime,    startMinute: 1200, endMinute: 1440),
                ]),
            ]

        case .nestling4to6:
            return [
                calmTemplate(group: group, blocks: [
                    .init(blockKind: .dreamTime,    startMinute: 0,    endMinute: 420),
                    .init(blockKind: .feedingNest,   startMinute: 420,  endMinute: 450),
                    .init(blockKind: .playGarden,   startMinute: 480,  endMinute: 540),
                    .init(blockKind: .dreamTime,    startMinute: 540,  endMinute: 660),
                    .init(blockKind: .feedingNest,   startMinute: 660,  endMinute: 690),
                    .init(blockKind: .freshAirWalk, startMinute: 720,  endMinute: 780),
                    .init(blockKind: .feedingNest,   startMinute: 780,  endMinute: 810),
                    .init(blockKind: .dreamTime,    startMinute: 840,  endMinute: 960),
                    .init(blockKind: .splashTime,   startMinute: 1140, endMinute: 1170),
                    .init(blockKind: .dreamTime,    startMinute: 1200, endMinute: 1440),
                ]),
            ]

        case .crawler7to12:
            return [
                calmTemplate(group: group, blocks: [
                    .init(blockKind: .dreamTime,    startMinute: 0,    endMinute: 420),
                    .init(blockKind: .feedingNest,   startMinute: 420,  endMinute: 460),
                    .init(blockKind: .playGarden,   startMinute: 480,  endMinute: 570),
                    .init(blockKind: .dreamTime,    startMinute: 570,  endMinute: 660),
                    .init(blockKind: .feedingNest,   startMinute: 660,  endMinute: 700),
                    .init(blockKind: .freshAirWalk, startMinute: 720,  endMinute: 810),
                    .init(blockKind: .feedingNest,   startMinute: 810,  endMinute: 840),
                    .init(blockKind: .dreamTime,    startMinute: 870,  endMinute: 960),
                    .init(blockKind: .splashTime,   startMinute: 1110, endMinute: 1150),
                    .init(blockKind: .dreamTime,    startMinute: 1200, endMinute: 1440),
                ]),
            ]

        case .toddler1to2:
            return [
                calmTemplate(group: group, blocks: [
                    .init(blockKind: .dreamTime,    startMinute: 0,    endMinute: 420),
                    .init(blockKind: .feedingNest,   startMinute: 420,  endMinute: 460),
                    .init(blockKind: .freshAirWalk, startMinute: 480,  endMinute: 570),
                    .init(blockKind: .playGarden,   startMinute: 570,  endMinute: 660),
                    .init(blockKind: .feedingNest,   startMinute: 660,  endMinute: 700),
                    .init(blockKind: .dreamTime,    startMinute: 720,  endMinute: 840),
                    .init(blockKind: .playGarden,   startMinute: 840,  endMinute: 930),
                    .init(blockKind: .feedingNest,   startMinute: 930,  endMinute: 960),
                    .init(blockKind: .splashTime,   startMinute: 1110, endMinute: 1150),
                    .init(blockKind: .dreamTime,    startMinute: 1200, endMinute: 1440),
                ]),
            ]

        case .explorer3to4:
            return [
                calmTemplate(group: group, blocks: [
                    .init(blockKind: .dreamTime,    startMinute: 0,    endMinute: 420),
                    .init(blockKind: .feedingNest,   startMinute: 420,  endMinute: 460),
                    .init(blockKind: .playGarden,   startMinute: 480,  endMinute: 570),
                    .init(blockKind: .freshAirWalk, startMinute: 600,  endMinute: 720),
                    .init(blockKind: .feedingNest,   startMinute: 720,  endMinute: 760),
                    .init(blockKind: .dreamTime,    startMinute: 780,  endMinute: 870),
                    .init(blockKind: .playGarden,   startMinute: 870,  endMinute: 960),
                    .init(blockKind: .feedingNest,   startMinute: 960,  endMinute: 990),
                    .init(blockKind: .familyRitual, startMinute: 1050, endMinute: 1110),
                    .init(blockKind: .splashTime,   startMinute: 1110, endMinute: 1150),
                    .init(blockKind: .dreamTime,    startMinute: 1200, endMinute: 1440),
                ]),
            ]

        case .adventurer5to7:
            return [
                calmTemplate(group: group, blocks: [
                    .init(blockKind: .dreamTime,    startMinute: 0,    endMinute: 420),
                    .init(blockKind: .feedingNest,   startMinute: 420,  endMinute: 460),
                    .init(blockKind: .playGarden,   startMinute: 480,  endMinute: 600),
                    .init(blockKind: .freshAirWalk, startMinute: 600,  endMinute: 720),
                    .init(blockKind: .feedingNest,   startMinute: 720,  endMinute: 760),
                    .init(blockKind: .freeSpirit,   startMinute: 780,  endMinute: 870),
                    .init(blockKind: .playGarden,   startMinute: 870,  endMinute: 960),
                    .init(blockKind: .feedingNest,   startMinute: 960,  endMinute: 990),
                    .init(blockKind: .familyRitual, startMinute: 1050, endMinute: 1110),
                    .init(blockKind: .splashTime,   startMinute: 1110, endMinute: 1150),
                    .init(blockKind: .dreamTime,    startMinute: 1260, endMinute: 1440),
                ]),
            ]
        }
    }

    private static func calmTemplate(
        group: AgeNestGroup,
        blocks: [TemplateBlockSeed]
    ) -> RoutineNestTemplate {
        RoutineNestTemplate(
            title: "Calm \(group.shortLabel)",
            ageGroup: group,
            style: .calm,
            blocks: blocks
        )
    }
}
