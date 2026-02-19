// LittleOneEntity.swift
// с17 — Daily Routine Without Stress
// All data models — parent-child themed naming

import Foundation

// MARK: - 👶 Child Profile

/// A child profile — the little one whose day we're planning.
struct LittleOneProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var petName: String                     // child's name or nickname
    var avatarEmoji: String                 // emoji avatar (🧒👶🦁🐣...)
    var ageNestGroup: AgeNestGroup          // current age group
    var birthSunrise: Date?                 // optional birth date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        petName: String = "",
        avatarEmoji: String = "👶",
        ageNestGroup: AgeNestGroup = .hatchling0to3,
        birthSunrise: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.petName = petName
        self.avatarEmoji = avatarEmoji
        self.ageNestGroup = ageNestGroup
        self.birthSunrise = birthSunrise
        self.createdAt = createdAt
    }
}

// MARK: - 🐣 Age Groups

/// Age nest groups — each with different routine templates.
enum AgeNestGroup: String, Codable, CaseIterable, Identifiable {
    case hatchling0to3   = "hatchling_0_3"
    case nestling4to6    = "nestling_4_6"
    case crawler7to12    = "crawler_7_12"
    case toddler1to2     = "toddler_1_2"
    case explorer3to4    = "explorer_3_4"
    case adventurer5to7  = "adventurer_5_7"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .hatchling0to3:  return "Hatchling (0–3 mo)"
        case .nestling4to6:   return "Nestling (4–6 mo)"
        case .crawler7to12:   return "Crawler (7–12 mo)"
        case .toddler1to2:    return "Toddler (1–2 yr)"
        case .explorer3to4:   return "Explorer (3–4 yr)"
        case .adventurer5to7: return "Adventurer (5–7 yr)"
        }
    }

    var shortLabel: String {
        switch self {
        case .hatchling0to3:  return "0–3m"
        case .nestling4to6:   return "4–6m"
        case .crawler7to12:   return "7–12m"
        case .toddler1to2:    return "1–2y"
        case .explorer3to4:   return "3–4y"
        case .adventurer5to7: return "5–7y"
        }
    }

    var iconSymbol: String {
        switch self {
        case .hatchling0to3:  return "🥚"
        case .nestling4to6:   return "🐣"
        case .crawler7to12:   return "🐥"
        case .toddler1to2:    return "🧒"
        case .explorer3to4:   return "🦸‍♂️"
        case .adventurer5to7: return "🚀"
        }
    }
}

// MARK: - 📦 Day Block — Core Activity Unit

/// A single block in the day timeline — sleep, meal, walk, etc.
struct CradleBlock: Codable, Identifiable, Equatable {
    let id: UUID
    var blockKind: BlockKind                // type of activity
    var startFeather: Int                   // start time in minutes from midnight
    var endFeather: Int                     // end time in minutes from midnight
    var completionMark: CompletionMark      // done / moved / skipped / pending
    var moodStamp: MoodStamp?              // optional mood after completion
    var moveCount: Int                      // how many times this block was moved
    var tinyNote: String                    // optional short note
    var reminderEnabled: Bool
    var customTitle: String?                // optional custom name (overrides blockKind.displayTitle)

    init(
        id: UUID = UUID(),
        blockKind: BlockKind,
        startFeather: Int,
        endFeather: Int,
        completionMark: CompletionMark = .pending,
        moodStamp: MoodStamp? = nil,
        moveCount: Int = 0,
        tinyNote: String = "",
        reminderEnabled: Bool = true,
        customTitle: String? = nil
    ) {
        self.id = id
        self.blockKind = blockKind
        self.startFeather = startFeather
        self.endFeather = endFeather
        self.completionMark = completionMark
        self.moodStamp = moodStamp
        self.moveCount = moveCount
        self.tinyNote = tinyNote
        self.reminderEnabled = reminderEnabled
        self.customTitle = customTitle
    }

    /// Display name — custom if set, otherwise blockKind default.
    var displayTitle: String {
        let t = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t != nil && !t!.isEmpty) ? t! : blockKind.displayTitle
    }

    /// Duration in minutes.
    var durationMinutes: Int {
        endFeather - startFeather
    }

    /// Formatted time string "HH:mm – HH:mm".
    var timeRangeLabel: String {
        let startH = startFeather / 60
        let startM = startFeather % 60
        let endH = endFeather / 60
        let endM = endFeather % 60
        return String(format: "%02d:%02d – %02d:%02d", startH, startM, endH, endM)
    }
}

// MARK: - 🧩 Block Kind — Activity Types

enum BlockKind: String, Codable, CaseIterable, Identifiable {
    case dreamTime      = "dream_time"       // sleep
    case feedingNest    = "feeding_nest"    // meal / feeding
    case napTime        = "nap_time"         // nap
    case freshAirWalk   = "fresh_air_walk"   // walk / outdoor
    case playGarden     = "play_garden"      // play / learning
    case splashTime     = "splash_time"      // bath / hygiene
    case readingTime    = "reading_time"     // reading
    case freeSpirit     = "free_spirit"      // free time
    case familyRitual   = "family_ritual"    // custom / other

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .dreamTime:     return "Sleep"
        case .feedingNest:   return "Meal"
        case .napTime:       return "Nap"
        case .freshAirWalk:  return "Walk"
        case .playGarden:    return "Play"
        case .splashTime:    return "Bath"
        case .readingTime:   return "Reading"
        case .freeSpirit:    return "Free Time"
        case .familyRitual:  return "Ritual"
        }
    }

    var sfIcon: String {
        switch self {
        case .dreamTime:     return "moon.zzz.fill"
        case .feedingNest:   return "fork.knife"
        case .napTime:       return "bed.double.fill"
        case .freshAirWalk:  return "leaf.fill"
        case .playGarden:    return "puzzlepiece.fill"
        case .splashTime:    return "drop.fill"
        case .readingTime:   return "book.fill"
        case .freeSpirit:    return "sparkles"
        case .familyRitual:  return "heart.fill"
        }
    }

    var emoji: String {
        switch self {
        case .dreamTime:     return "🌙"
        case .feedingNest:   return "🍼"
        case .napTime:       return "😴"
        case .freshAirWalk:  return "🌿"
        case .playGarden:    return "🧩"
        case .splashTime:    return "💧"
        case .readingTime:   return "📖"
        case .freeSpirit:    return "✨"
        case .familyRitual:  return "💛"
        }
    }

    /// XP reward for completing this block kind.
    var sproutXP: Int {
        switch self {
        case .dreamTime:     return 15
        case .feedingNest:   return 10
        case .napTime:      return 12
        case .freshAirWalk:  return 20
        case .playGarden:    return 15
        case .splashTime:    return 10
        case .readingTime:   return 15
        case .freeSpirit:    return 5
        case .familyRitual:  return 25
        }
    }
}

// MARK: - ✅ Completion Mark

enum CompletionMark: String, Codable, CaseIterable {
    case pending    = "pending"
    case done       = "done"
    case moved      = "moved"
    case skipped    = "skipped"

    var displayLabel: String {
        switch self {
        case .pending:  return "Upcoming"
        case .done:     return "Done"
        case .moved:    return "Moved"
        case .skipped:  return "Skipped"
        }
    }

    var sfIcon: String {
        switch self {
        case .pending:  return "clock"
        case .done:     return "checkmark.circle.fill"
        case .moved:    return "arrow.right.circle.fill"
        case .skipped:  return "xmark.circle"
        }
    }
}

// MARK: - 😊 Mood Stamp

enum MoodStamp: String, Codable, CaseIterable {
    case calm       = "calm"
    case neutral    = "neutral"
    case tough      = "tough"

    var emoji: String {
        switch self {
        case .calm:     return "😌"
        case .neutral:  return "😐"
        case .tough:    return "😫"
        }
    }

    var label: String {
        switch self {
        case .calm:     return "Calm"
        case .neutral:  return "Neutral"
        case .tough:    return "Tough"
        }
    }
}

// MARK: - 📅 Day Plan — Collection of Blocks

/// One full day's schedule for a child.
struct DayCradle: Codable, Identifiable, Equatable {
    let id: UUID
    var dateKey: String                     // "yyyy-MM-dd"
    var profileId: UUID                     // linked to LittleOneProfile
    var blocks: [CradleBlock]
    var dayNote: String

    init(
        id: UUID = UUID(),
        dateKey: String,
        profileId: UUID,
        blocks: [CradleBlock] = [],
        dayNote: String = ""
    ) {
        self.id = id
        self.dateKey = dateKey
        self.profileId = profileId
        self.blocks = blocks
        self.dayNote = dayNote
    }

    /// Sorted blocks by start time.
    var sortedNest: [CradleBlock] {
        blocks.sorted { $0.startFeather < $1.startFeather }
    }

    /// Completed count.
    var doneLullabies: Int {
        blocks.filter { $0.completionMark == .done }.count
    }

    /// Total count.
    var totalLullabies: Int {
        blocks.count
    }

    /// Completion percentage.
    var completionWarmth: Double {
        guard totalLullabies > 0 else { return 0 }
        return Double(doneLullabies) / Double(totalLullabies)
    }
}

// MARK: - 🏆 Gamification — Parent Guardian XP

/// Tracks the parent's gamification progress.
struct GuardianProgress: Codable, Equatable {
    var totalStardust: Int                  // total XP earned
    var currentStreak: Int                  // consecutive days with ≥50% completion
    var longestStreak: Int                  // best streak ever
    var completedDaysCount: Int             // total days with activity
    var earnedBadges: [NestBadge]           // unlocked achievements
    var lastActiveDate: String              // "yyyy-MM-dd"

    init(
        totalStardust: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        completedDaysCount: Int = 0,
        earnedBadges: [NestBadge] = [],
        lastActiveDate: String = ""
    ) {
        self.totalStardust = totalStardust
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.completedDaysCount = completedDaysCount
        self.earnedBadges = earnedBadges
        self.lastActiveDate = lastActiveDate
    }

    /// Guardian level based on total XP.
    var guardianLevel: GuardianLevel {
        GuardianLevel.fromStardust(totalStardust)
    }

    /// XP needed for next level.
    var stardustToNextLevel: Int {
        let next = guardianLevel.nextLevelThreshold
        return max(0, next - totalStardust)
    }

    /// Progress fraction within current level (0...1).
    var levelWarmth: Double {
        let level = guardianLevel
        let base = level.stardustThreshold
        let next = level.nextLevelThreshold
        let range = next - base
        guard range > 0 else { return 1.0 }
        return Double(totalStardust - base) / Double(range)
    }
}

// MARK: - 🎖 Guardian Levels

enum GuardianLevel: Int, Codable, CaseIterable {
    case seedling       = 1
    case sprout         = 2
    case blossom        = 3
    case guardian       = 4
    case elderTree      = 5

    var displayTitle: String {
        switch self {
        case .seedling:   return "Seedling"
        case .sprout:     return "Sprout"
        case .blossom:    return "Blossom"
        case .guardian:    return "Guardian"
        case .elderTree:  return "Elder Tree"
        }
    }

    var emoji: String {
        switch self {
        case .seedling:   return "🌱"
        case .sprout:     return "🌿"
        case .blossom:    return "🌸"
        case .guardian:    return "🌳"
        case .elderTree:  return "🏔"
        }
    }

    var stardustThreshold: Int {
        switch self {
        case .seedling:   return 0
        case .sprout:     return 200
        case .blossom:    return 600
        case .guardian:    return 1500
        case .elderTree:  return 3500
        }
    }

    var nextLevelThreshold: Int {
        switch self {
        case .seedling:   return 200
        case .sprout:     return 600
        case .blossom:    return 1500
        case .guardian:    return 3500
        case .elderTree:  return 7000
        }
    }

    static func fromStardust(_ xp: Int) -> GuardianLevel {
        let sorted = Self.allCases.sorted { $0.stardustThreshold > $1.stardustThreshold }
        return sorted.first { xp >= $0.stardustThreshold } ?? .seedling
    }
}

// MARK: - 🏅 Nest Badges — Achievements

struct NestBadge: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }
}

/// Predefined badge catalog.
enum NestBadgeCatalog {

    static let firstStep = NestBadge(
        id: "first_step",
        title: "First Step",
        description: "Complete your first activity block",
        emoji: "👣"
    )

    static let earlyBird = NestBadge(
        id: "early_bird",
        title: "Early Bird",
        description: "Mark a block done before 8 AM",
        emoji: "🐦"
    )

    static let streakFlame3 = NestBadge(
        id: "streak_3",
        title: "Warm Hearth",
        description: "Maintain a 3-day streak",
        emoji: "🔥"
    )

    static let streakFlame7 = NestBadge(
        id: "streak_7",
        title: "Steady Rhythm",
        description: "Maintain a 7-day streak",
        emoji: "⭐️"
    )

    static let perfectDay = NestBadge(
        id: "perfect_day",
        title: "Golden Day",
        description: "Complete every block in one day",
        emoji: "🌟"
    )

    static let nightOwl = NestBadge(
        id: "night_owl",
        title: "Night Owl",
        description: "Mark a block after 10 PM",
        emoji: "🦉"
    )

    static let flexibleParent = NestBadge(
        id: "flexible",
        title: "Flexible Flow",
        description: "Move 5 blocks without skipping any",
        emoji: "🌊"
    )

    static let centurion = NestBadge(
        id: "centurion",
        title: "Centurion",
        description: "Complete 100 blocks total",
        emoji: "💯"
    )

    static let allBadges: [NestBadge] = [
        firstStep, earlyBird, streakFlame3, streakFlame7,
        perfectDay, nightOwl, flexibleParent, centurion
    ]
}

// MARK: - ⚙️ App Settings

/// Persisted settings — no theme selection (always dark premium).
struct NestSettings: Codable, Equatable {
    var quietHoursStart: Int                // minutes from midnight (e.g. 21*60 = 1260)
    var quietHoursEnd: Int                  // minutes from midnight (e.g. 7*60 = 420)
    var reminderStyle: ReminderStyle
    var isQuietModeActive: Bool
    var hasCompletedOnboarding: Bool
    var activeProfileId: UUID?
    var parentAvatarEmoji: String           // parent's own emoji avatar

    init(
        quietHoursStart: Int = 1260,
        quietHoursEnd: Int = 420,
        reminderStyle: ReminderStyle = .balanced,
        isQuietModeActive: Bool = false,
        hasCompletedOnboarding: Bool = false,
        activeProfileId: UUID? = nil,
        parentAvatarEmoji: String = "🦸"
    ) {
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.reminderStyle = reminderStyle
        self.isQuietModeActive = isQuietModeActive
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.activeProfileId = activeProfileId
        self.parentAvatarEmoji = parentAvatarEmoji
    }
}

// MARK: - 🔔 Reminder Style

enum ReminderStyle: String, Codable, CaseIterable {
    case whisper     = "whisper"        // very gentle — 1 notification, no repeat
    case balanced    = "balanced"       // 1 + soft reminder after 10–15 min
    case clockwork   = "clockwork"      // 1 + repeat after 5–10 min

    var displayTitle: String {
        switch self {
        case .whisper:   return "Whisper"
        case .balanced:  return "Balanced"
        case .clockwork: return "Clockwork"
        }
    }

    var subtitle: String {
        switch self {
        case .whisper:   return "One gentle nudge, no repeats"
        case .balanced:  return "Nudge + soft follow-up"
        case .clockwork: return "Nudge + quick follow-up"
        }
    }

    var sfIcon: String {
        switch self {
        case .whisper:   return "bell"
        case .balanced:  return "bell.badge"
        case .clockwork: return "bell.badge.fill"
        }
    }
}

// MARK: - 📊 Insight Models — For Growth Garden Tab

/// Daily summary stats.
struct DaySummaryNest: Equatable {
    let dateKey: String
    let totalBlocks: Int
    let doneCount: Int
    let movedCount: Int
    let skippedCount: Int
    let pendingCount: Int
    let totalXPEarned: Int
    let mostMovedKind: BlockKind?
    let mostStableKind: BlockKind?

    var completionPercent: Double {
        guard totalBlocks > 0 else { return 0 }
        return Double(doneCount) / Double(totalBlocks) * 100
    }
}

/// Weekly summary stats.
struct WeeklySummaryNest: Equatable {
    let weekLabel: String               // e.g. "Feb 10 – Feb 16"
    let dailySummaries: [DaySummaryNest]
    let averageCompletion: Double
    let bestDay: String?
    let worstDay: String?
    let streakDays: Int
    let totalXP: Int
}

// MARK: - 📋 Template Model

/// Predefined routine template per age group.
struct RoutineNestTemplate: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var ageGroup: AgeNestGroup
    var style: TemplateStyle
    var blocks: [TemplateBlockSeed]

    init(
        id: UUID = UUID(),
        title: String,
        ageGroup: AgeNestGroup,
        style: TemplateStyle,
        blocks: [TemplateBlockSeed]
    ) {
        self.id = id
        self.title = title
        self.ageGroup = ageGroup
        self.style = style
        self.blocks = blocks
    }
}

enum TemplateStyle: String, Codable, CaseIterable {
    case calm       = "calm"
    case active     = "active"
    case structured = "structured"

    var displayTitle: String {
        switch self {
        case .calm:       return "Calm"
        case .active:     return "Active"
        case .structured: return "Structured"
        }
    }

    var emoji: String {
        switch self {
        case .calm:       return "🕊"
        case .active:     return "⚡️"
        case .structured: return "📐"
        }
    }
}

/// A seed block within a template (generates CradleBlock on apply).
struct TemplateBlockSeed: Codable, Identifiable, Equatable {
    let id: UUID
    var blockKind: BlockKind
    var startMinute: Int
    var endMinute: Int

    init(
        id: UUID = UUID(),
        blockKind: BlockKind,
        startMinute: Int,
        endMinute: Int
    ) {
        self.id = id
        self.blockKind = blockKind
        self.startMinute = startMinute
        self.endMinute = endMinute
    }
}

// MARK: - 📆 Date Helpers

enum NestDateHelper {

    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func todayKey() -> String {
        dayKeyFormatter.string(from: Date())
    }

    static func dateKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        dayKeyFormatter.date(from: key)
    }

    static func displayDate(_ key: String) -> String {
        guard let date = date(from: key) else { return key }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    static func isToday(_ key: String) -> Bool {
        key == todayKey()
    }

    static func minutesNow() -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    static func timeString(from minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}
