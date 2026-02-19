// CradleDayBrain.swift
// с17 — Daily Routine Without Stress
// Day Timeline — ViewModel (logic separated from View)

import SwiftUI
import Combine

// MARK: - 🧠 Cradle Day Brain — Day Timeline ViewModel

final class CradleDayBrain: ObservableObject {

    // MARK: – Published State

    @Published var currentDateKey: String = NestDateHelper.todayKey()
    @Published var blocks: [CradleBlock] = []
    @Published var dayNote: String = ""
    @Published var isQuietMode: Bool = false

    // MARK: – Computed

    var sortedBlocks: [CradleBlock] {
        blocks.sorted { $0.startFeather < $1.startFeather }
    }

    var doneCount: Int {
        blocks.filter { $0.completionMark == .done }.count
    }

    var totalCount: Int {
        blocks.count
    }

    var completionFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }

    var todayXP: Int {
        blocks
            .filter { $0.completionMark == .done }
            .reduce(0) { $0 + $1.blockKind.sproutXP }
    }

    var isToday: Bool {
        NestDateHelper.isToday(currentDateKey)
    }

    var displayDate: String {
        NestDateHelper.displayDate(currentDateKey)
    }

    var completionEncouragement: String {
        let ratio = completionFraction
        if totalCount == 0 {
            return "Add blocks to start your day"
        } else if ratio == 0 {
            return "A fresh day awaits ✨"
        } else if ratio < 0.3 {
            return "You're warming up 🌅"
        } else if ratio < 0.5 {
            return "Nice momentum! Keep going 🌿"
        } else if ratio < 0.8 {
            return "More than halfway there 💫"
        } else if ratio < 1.0 {
            return "Almost a golden day! 🌟"
        } else {
            return "Golden day achieved! 🏆"
        }
    }

    // MARK: – Private

    private var nestMemory: NestMemory?
    private var currentDayCradle: DayCradle?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 🔗 Memory Binding

    func attachMemory(_ memory: NestMemory) {
        self.nestMemory = memory
        self.isQuietMode = memory.settings.isQuietModeActive
    }

    // MARK: - 📅 Load Day

    func loadToday() {
        currentDateKey = NestDateHelper.todayKey()
        loadDay(for: currentDateKey)
    }

    func loadDay(for dateKey: String) {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId else {
            blocks = []
            dayNote = ""
            currentDayCradle = nil
            return
        }

        currentDateKey = dateKey

        // loadOrCreateToday only for today; for other dates just load existing
        if NestDateHelper.isToday(dateKey) {
            currentDayCradle = memory.loadOrCreateToday(profileId: profileId)
        } else {
            currentDayCradle = memory.loadDayCradle(profileId: profileId, dateKey: dateKey)
        }

        blocks = currentDayCradle?.blocks ?? []
        dayNote = currentDayCradle?.dayNote ?? ""

        // Badge evaluation on load (for today and historical days)
        if let cradle = currentDayCradle {
            var updated = cradle
            updated.blocks = blocks
            memory.evaluateBadges(day: updated)
        }
    }

    // MARK: - 🔀 Date Navigation

    func goToPreviousDay() {
        guard let current = NestDateHelper.date(from: currentDateKey),
              let prev = Calendar.current.date(byAdding: .day, value: -1, to: current) else { return }
        let key = NestDateHelper.dateKey(for: prev)
        loadDay(for: key)
    }

    func goToNextDay() {
        guard let current = NestDateHelper.date(from: currentDateKey),
              let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else { return }
        let key = NestDateHelper.dateKey(for: next)
        loadDay(for: key)
    }

    // MARK: - ➕ Add Block

    /// Returns true if the new block would overlap with existing blocks.
    func wouldOverlap(startMinute: Int, durationMinutes: Int, excludingBlockId: UUID? = nil) -> Bool {
        let endMinute = startMinute + durationMinutes
        return blocks.contains { block in
            block.id != excludingBlockId &&
            (startMinute < block.endFeather && endMinute > block.startFeather)
        }
    }

    func addBlock(kind: BlockKind, startMinute: Int, durationMinutes: Int, customTitle: String? = nil) -> Bool {
        if wouldOverlap(startMinute: startMinute, durationMinutes: durationMinutes) {
            return false
        }
        let trimmed = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let newBlock = CradleBlock(
            blockKind: kind,
            startFeather: startMinute,
            endFeather: startMinute + durationMinutes,
            customTitle: (trimmed != nil && !trimmed!.isEmpty) ? trimmed : nil
        )
        blocks.append(newBlock)
        persistCurrentDay()
        return true
    }

    // MARK: - ✅ Quick Mark Done

    func quickMarkDone(blockId: UUID) {
        guard let index = blocks.firstIndex(where: { $0.id == blockId }) else { return }

        NestHaptic.impact(.light)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            blocks[index].completionMark = .done
        }

        // Award XP
        let xp = blocks[index].blockKind.sproutXP
        nestMemory?.awardStardust(xp)

        persistCurrentDay()
        checkBadgesAfterMark()
    }

    // MARK: - 📋 Mark Block (from detail sheet)

    func markBlock(blockId: UUID, status: CompletionMark, mood: MoodStamp?, note: String, customTitle: String? = nil) {
        guard let index = blocks.firstIndex(where: { $0.id == blockId }) else { return }

        let wasAlreadyDone = blocks[index].completionMark == .done

        blocks[index].completionMark = status
        blocks[index].moodStamp = mood
        blocks[index].tinyNote = note
        if let title = customTitle {
            blocks[index].customTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : title
        }

        if status == .moved {
            blocks[index].moveCount += 1
        }

        // Award XP only if newly marked done
        if status == .done && !wasAlreadyDone {
            let xp = blocks[index].blockKind.sproutXP
            nestMemory?.awardStardust(xp)
        }

        persistCurrentDay()
        checkBadgesAfterMark()
    }

    func updateBlockCustomTitle(blockId: UUID, customTitle: String?) {
        guard let index = blocks.firstIndex(where: { $0.id == blockId }) else { return }
        let trimmed = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        blocks[index].customTitle = (trimmed != nil && !trimmed!.isEmpty) ? trimmed : nil
        persistCurrentDay()
    }

    // MARK: - ⏰ Move Block (from context menu)

    func moveBlock(blockId: UUID, byMinutes delta: Int) {
        guard let index = blocks.firstIndex(where: { $0.id == blockId }) else { return }
        let block = blocks[index]
        let newStart = max(0, min(block.startFeather + delta, 24 * 60 - block.durationMinutes))
        let newEnd = newStart + block.durationMinutes
        if wouldOverlap(startMinute: newStart, durationMinutes: block.durationMinutes, excludingBlockId: blockId) {
            return
        }
        NestHaptic.impact(.medium)
        blocks[index].startFeather = newStart
        blocks[index].endFeather = newEnd
        blocks[index].moveCount += 1
        blocks[index].completionMark = .moved
        persistCurrentDay()
        checkBadgesAfterMark()
    }

    // MARK: - 🗑 Remove Block

    func removeBlock(blockId: UUID) {
        withAnimation(.easeOut(duration: 0.25)) {
            blocks.removeAll { $0.id == blockId }
        }
        persistCurrentDay()
    }

    // MARK: - 📝 Day Note

    func saveDayNote(_ text: String) {
        dayNote = text
        persistCurrentDay()
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

    // MARK: - 📋 Templates

    func applyTemplate(_ template: RoutineNestTemplate) {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId else { return }

        let cradle = memory.applyTemplate(template, profileId: profileId, dateKey: currentDateKey)
        blocks = cradle.blocks
        dayNote = cradle.dayNote
        currentDayCradle = cradle
        persistCurrentDay()
    }

    /// Creates a template from current blocks. Returns the created template.
    func createTemplateFromCurrentDay(title: String) -> RoutineNestTemplate? {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId,
              let profile = memory.activeProfile else { return nil }

        var cradle = currentDayCradle ?? DayCradle(dateKey: currentDateKey, profileId: profileId)
        cradle.blocks = blocks
        return memory.createTemplateFromDay(day: cradle, title: title, ageGroup: profile.ageNestGroup)
    }

    // MARK: - 📋 Duplicate to Tomorrow

    /// Returns true if tomorrow already has blocks (overwrite would lose data).
    func tomorrowHasExistingBlocks() -> Bool {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId,
              let today = NestDateHelper.date(from: currentDateKey),
              let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return false
        }
        let tomorrowKey = NestDateHelper.dateKey(for: tomorrow)
        let existing = memory.loadDayCradle(profileId: profileId, dateKey: tomorrowKey)
        return (existing?.blocks.isEmpty == false)
    }

    func duplicateToTomorrow() {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId,
              let today = NestDateHelper.date(from: currentDateKey),
              let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return }

        let tomorrowKey = NestDateHelper.dateKey(for: tomorrow)

        // Create fresh blocks (reset status)
        let freshBlocks = blocks.map { block in
            CradleBlock(
                blockKind: block.blockKind,
                startFeather: block.startFeather,
                endFeather: block.endFeather,
                completionMark: .pending,
                moodStamp: nil,
                moveCount: 0,
                tinyNote: "",
                reminderEnabled: block.reminderEnabled,
                customTitle: block.customTitle
            )
        }

        let tomorrowCradle = DayCradle(
            dateKey: tomorrowKey,
            profileId: profileId,
            blocks: freshBlocks
        )

        memory.saveDayCradle(tomorrowCradle)
    }

    // MARK: - ⏰ Current Time Slot Detection

    func isCurrentTimeSlot(_ block: CradleBlock) -> Bool {
        guard isToday else { return false }
        let now = NestDateHelper.minutesNow()
        return now >= block.startFeather && now < block.endFeather
    }

    // MARK: - 🏆 Badge Evaluation

    private func checkBadgesAfterMark() {
        guard let memory = nestMemory, let cradle = currentDayCradle else { return }

        // Rebuild cradle with current blocks
        var updated = cradle
        updated.blocks = blocks

        memory.evaluateBadges(day: updated)

        // Record day completion for streak tracking
        if isToday {
            memory.recordDayCompletion(
                dateKey: currentDateKey,
                completionRatio: completionFraction
            )
        }
    }

    // MARK: - 💾 Persist

    private func persistCurrentDay() {
        guard let memory = nestMemory,
              let profileId = memory.settings.activeProfileId else { return }

        var cradle = currentDayCradle ?? DayCradle(
            dateKey: currentDateKey,
            profileId: profileId
        )

        cradle.blocks = blocks
        cradle.dayNote = dayNote
        currentDayCradle = cradle

        memory.saveDayCradle(cradle)
    }
}
