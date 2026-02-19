// FamilyNestBrain.swift
// с17 — Daily Routine Without Stress
// Settings — ViewModel (logic separated from View)

import SwiftUI
import Combine

// MARK: - 🧠 Family Nest Brain — Settings ViewModel

final class FamilyNestBrain: ObservableObject {

    // MARK: – Published State

    @Published var parentAvatarEmoji: String = "🦸"
    @Published var currentReminderStyle: ReminderStyle = .balanced
    @Published var isQuietMode: Bool = false
    @Published var quietStart: Int = 1260       // 21:00
    @Published var quietEnd: Int = 420          // 07:00

    // MARK: – Private

    private var nestMemory: NestMemory?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 🔗 Memory Binding

    func attachMemory(_ memory: NestMemory) {
        self.nestMemory = memory

        // Sync state from stored settings
        let settings = memory.settings
        parentAvatarEmoji = settings.parentAvatarEmoji
        currentReminderStyle = settings.reminderStyle
        isQuietMode = settings.isQuietModeActive
        quietStart = settings.quietHoursStart
        quietEnd = settings.quietHoursEnd

        // Observe memory changes
        memory.$settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                self?.parentAvatarEmoji = updated.parentAvatarEmoji
                self?.currentReminderStyle = updated.reminderStyle
                self?.isQuietMode = updated.isQuietModeActive
                self?.quietStart = updated.quietHoursStart
                self?.quietEnd = updated.quietHoursEnd
            }
            .store(in: &cancellables)
    }

    // MARK: - 🎭 Parent Avatar

    func setParentAvatar(_ emoji: String) {
        guard let memory = nestMemory else { return }

        parentAvatarEmoji = emoji

        var settings = memory.settings
        settings.parentAvatarEmoji = emoji
        memory.tuckinSettings(settings)
    }

    // MARK: - 👶 Child Profile Management

    func addChild(name: String, emoji: String, ageGroup: AgeNestGroup) {
        guard let memory = nestMemory else { return }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let profile = LittleOneProfile(
            petName: trimmed.isEmpty ? "Little One" : trimmed,
            avatarEmoji: emoji,
            ageNestGroup: ageGroup,
            createdAt: Date()
        )

        memory.nestNewProfile(profile)

        // Start with empty day — user adds blocks or applies template themselves
    }

    func updateChild(id: UUID, name: String, emoji: String, ageGroup: AgeNestGroup) {
        guard let memory = nestMemory else { return }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        var profile = LittleOneProfile(
            id: id,
            petName: trimmed.isEmpty ? "Little One" : trimmed,
            avatarEmoji: emoji,
            ageNestGroup: ageGroup
        )

        // Preserve original creation date
        if let existing = memory.profiles.first(where: { $0.id == id }) {
            profile.birthSunrise = existing.birthSunrise
            profile.createdAt = existing.createdAt
        }

        memory.updateProfile(profile)
    }

    func removeChild(id: UUID) {
        guard let memory = nestMemory else { return }
        memory.removeProfile(id)
    }

    func switchToProfile(_ profileId: UUID) {
        guard let memory = nestMemory else { return }
        memory.switchActiveProfile(to: profileId)
    }

    // MARK: - 🔔 Reminder Style

    func setReminderStyle(_ style: ReminderStyle) {
        guard let memory = nestMemory else { return }

        currentReminderStyle = style

        var settings = memory.settings
        settings.reminderStyle = style
        memory.tuckinSettings(settings)
        memory.rescheduleTodayNotificationsIfNeeded()
    }

    // MARK: - 🌙 Quiet Mode

    func toggleQuietMode() {
        guard let memory = nestMemory else { return }

        isQuietMode.toggle()

        var settings = memory.settings
        settings.isQuietModeActive = isQuietMode
        memory.tuckinSettings(settings)
        memory.rescheduleTodayNotificationsIfNeeded()
    }

    // MARK: - 🕐 Quiet Hours

    func setQuietHours(start: Int, end: Int) {
        guard let memory = nestMemory else { return }

        quietStart = start
        quietEnd = end

        var settings = memory.settings
        settings.quietHoursStart = start
        settings.quietHoursEnd = end
        memory.tuckinSettings(settings)
        memory.rescheduleTodayNotificationsIfNeeded()
    }

    /// Formatted quiet hours start label "HH:mm".
    var quietHoursStartLabel: String {
        formatMinutes(quietStart)
    }

    /// Formatted quiet hours end label "HH:mm".
    var quietHoursEndLabel: String {
        formatMinutes(quietEnd)
    }

    private func formatMinutes(_ totalMinutes: Int) -> String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return String(format: "%02d:%02d", h % 24, m)
    }

    // MARK: - 📤 Share Summary

    /// Generates a text summary of the week to share with a partner.
    var shareSummaryText: String {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId else {
            return "No data yet — start tracking your routine with \(NestAppName.displayName)!"
        }

        let weekly = memory.buildWeeklySummary(profileId: profileId)
        let gp = memory.guardianProgress
        let profile = memory.activeProfile

        var lines: [String] = []

        lines.append("🌙 \(NestAppName.displayName) Weekly Snapshot")
        lines.append("")

        if let profile = profile {
            lines.append("👶 \(profile.avatarEmoji) \(profile.petName) • \(profile.ageNestGroup.displayTitle)")
        }

        lines.append("")
        lines.append("📊 Week: \(weekly.weekLabel)")
        lines.append("✅ Average completion: \(String(format: "%.0f%%", weekly.averageCompletion))")
        lines.append("🔥 Current streak: \(weekly.streakDays) days")
        lines.append("✦ Stardust earned: +\(weekly.totalXP)")
        lines.append("")

        // Daily breakdown
        if !weekly.dailySummaries.isEmpty {
            lines.append("📅 Daily breakdown:")
            for day in weekly.dailySummaries.reversed() {
                let dateLabel = NestDateHelper.displayDate(day.dateKey)
                let mark = day.completionPercent >= 80 ? "🟢"
                    : day.completionPercent >= 50 ? "🟡"
                    : day.completionPercent > 0 ? "🟠"
                    : "⚪️"
                lines.append("  \(mark) \(dateLabel): \(day.doneCount)/\(day.totalBlocks) done")
            }
            lines.append("")
        }

        // Best/worst
        if let best = weekly.bestDay {
            lines.append("🌟 Best day: \(NestDateHelper.displayDate(best))")
        }
        if let worst = weekly.worstDay, worst != weekly.bestDay {
            lines.append("🌊 Toughest day: \(NestDateHelper.displayDate(worst))")
        }

        lines.append("")
        lines.append("\(gp.guardianLevel.emoji) Guardian Level: \(gp.guardianLevel.displayTitle) (Lv.\(gp.guardianLevel.rawValue))")
        lines.append("✦ Total stardust: \(gp.totalStardust)")
        lines.append("🏅 Badges: \(gp.earnedBadges.count)/\(NestBadgeCatalog.allBadges.count)")

        lines.append("")
        lines.append("— Sent from \(NestAppName.displayName)")

        return lines.joined(separator: "\n")
    }

    // MARK: - 🗑 Reset

    func resetAllData() {
        guard let memory = nestMemory else { return }
        memory.resetAllNestData()

        // Reset local state
        parentAvatarEmoji = "🦸"
        currentReminderStyle = .balanced
        isQuietMode = false
        quietStart = 1260
        quietEnd = 420
    }
}
