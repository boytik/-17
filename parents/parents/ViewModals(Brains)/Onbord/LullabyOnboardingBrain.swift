

import SwiftUI
import Combine

// MARK: - 🧭 Onboarding Steps

enum OnboardingLullaby: Int, CaseIterable, Comparable {
    case welcome        = 0
    case childProfile   = 1
    case templatePick   = 2
    case reminderStyle  = 3
    case nestReady      = 4

    static func < (lhs: OnboardingLullaby, rhs: OnboardingLullaby) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - 🧠 Lullaby Onboarding Brain — ViewModel

final class LullabyOnboardingBrain: ObservableObject {

    // MARK: – Navigation

    @Published var currentLullaby: OnboardingLullaby = .welcome

    // MARK: – Page 2: Child Profile Draft

    @Published var childNameDraft: String = ""
    @Published var selectedAvatarEmoji: String = "👶"
    @Published var selectedAgeGroup: AgeNestGroup = .hatchling0to3

    // MARK: – Page 3: Template (optional — default is empty day)

    @Published var selectedTemplateStyle: TemplateStyle? = nil  // nil = start empty
    @Published var previewBlocks: [TemplateBlockSeed] = []

    // MARK: – Page 4: Reminders

    @Published var selectedReminderStyle: ReminderStyle = .balanced

    // MARK: – Internal

    private var nestMemory: NestMemory?
    private var cancellables = Set<AnyCancellable>()

    // MARK: – Init

    init() {
        // Watch template style changes to update preview
        $selectedTemplateStyle
            .combineLatest($selectedAgeGroup)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] style, age in
                if let style = style {
                    self?.refreshPreviewBlocks(style: style, age: age)
                } else {
                    self?.previewBlocks = []
                }
            }
            .store(in: &cancellables)
    }

    // MARK: – Memory Binding

    func attachMemory(_ memory: NestMemory) {
        self.nestMemory = memory
    }

    // MARK: - 🔀 Navigation

    func stepForward() {
        guard let next = OnboardingLullaby(rawValue: currentLullaby.rawValue + 1) else { return }

        // Validate current step before proceeding
        if currentLullaby == .childProfile {
            // Age group is always selected (has default), name is optional — no block
        }

        // templatePick: selectedTemplateStyle can stay nil (empty day)

        withAnimation(.easeInOut(duration: 0.35)) {
            currentLullaby = next
        }
    }

    func stepBack() {
        guard let prev = OnboardingLullaby(rawValue: currentLullaby.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentLullaby = prev
        }
    }

    func jumpTo(_ step: OnboardingLullaby) {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentLullaby = step
        }
    }

    // MARK: - 🏁 Finish Onboarding

    func finishOnboarding() {
        guard let memory = nestMemory else { return }

        // 1. Create child profile
        let profile = LittleOneProfile(
            petName: childDisplayName,
            avatarEmoji: selectedAvatarEmoji,
            ageNestGroup: selectedAgeGroup,
            birthSunrise: nil,
            createdAt: Date()
        )
        memory.nestNewProfile(profile)

        // 2. Create today — empty by default, or apply template if user chose one
        let todayKey = NestDateHelper.todayKey()
        let dayCradle: DayCradle
        if let template = selectedTemplateToApply {
            dayCradle = memory.applyTemplate(template, profileId: profile.id, dateKey: todayKey)
        } else {
            dayCradle = DayCradle(dateKey: todayKey, profileId: profile.id, blocks: [])
            memory.saveDayCradle(dayCradle)
        }

        // 3. Save reminder style
        var settings = memory.settings
        settings.reminderStyle = selectedReminderStyle
        settings.activeProfileId = profile.id
        settings.hasCompletedOnboarding = true
        memory.tuckinSettings(settings)

        // 4. Award onboarding XP
        memory.awardStardust(50)

        // 5. Mark onboarding complete (redundant safety)
        memory.markOnboardingComplete()

        // 6. Update today's cradle in memory
        memory.todayCradle = dayCradle
    }

    // MARK: - 📋 Template Resolution

    /// Build the template based on selected style + age group.
    private func resolveTemplate() -> RoutineNestTemplate {
        let style = selectedTemplateStyle ?? .calm

        // Get default templates for selected age group
        let defaults = NestTemplateSeedlings.defaultTemplates(for: selectedAgeGroup)

        // If we have a matching template, use it
        if let match = defaults.first {
            // Adjust blocks based on style
            return applyStyleVariation(base: match, style: style)
        }

        // Fallback: generate a basic template
        return fallbackTemplate(style: style)
    }

    /// Applies style variation to a base template.
    /// Calm = as-is, Active = more outdoor/play, Structured = tighter slots.
    private func applyStyleVariation(
        base: RoutineNestTemplate,
        style: TemplateStyle
    ) -> RoutineNestTemplate {
        var template = base
        template.style = style
        template.title = "\(style.displayTitle) \(selectedAgeGroup.shortLabel)"

        switch style {
        case .calm:
            // Default is already calm — no modifications
            break

        case .active:
            // Extend outdoor blocks, add extra play block
            template.blocks = base.blocks.map { seed in
                var modified = seed
                if seed.blockKind == .freshAirWalk {
                    // Extend walks by 30 minutes
                    modified.endMinute = min(seed.endMinute + 30, seed.endMinute + 30)
                }
                if seed.blockKind == .freeSpirit {
                    // Convert free time to play
                    modified.blockKind = .playGarden
                }
                return modified
            }

        case .structured:
            // Tighten blocks: reduce gaps, make durations more uniform
            template.blocks = base.blocks.map { seed in
                var modified = seed
                let duration = seed.endMinute - seed.startMinute
                if duration > 90 && seed.blockKind != .dreamTime {
                    // Cap non-sleep blocks at 90 minutes
                    modified.endMinute = seed.startMinute + 90
                }
                return modified
            }
        }

        return template
    }

    /// Emergency fallback if no templates found.
    private func fallbackTemplate(style: TemplateStyle) -> RoutineNestTemplate {
        RoutineNestTemplate(
            title: "\(style.displayTitle) Day",
            ageGroup: selectedAgeGroup,
            style: style,
            blocks: [
                .init(blockKind: .dreamTime,    startMinute: 0,    endMinute: 420),
                .init(blockKind: .feedingNest,   startMinute: 420,  endMinute: 460),
                .init(blockKind: .playGarden,   startMinute: 480,  endMinute: 570),
                .init(blockKind: .feedingNest,   startMinute: 600,  endMinute: 640),
                .init(blockKind: .freshAirWalk, startMinute: 660,  endMinute: 750),
                .init(blockKind: .dreamTime,    startMinute: 780,  endMinute: 870),
                .init(blockKind: .feedingNest,   startMinute: 900,  endMinute: 940),
                .init(blockKind: .splashTime,   startMinute: 1110, endMinute: 1150),
                .init(blockKind: .dreamTime,    startMinute: 1200, endMinute: 1440),
            ]
        )
    }

    // MARK: - 🔍 Preview Blocks

    /// Refresh the block preview strip shown on template page.
    private func refreshPreviewBlocks(style: TemplateStyle, age: AgeNestGroup) {
        let defaults = NestTemplateSeedlings.defaultTemplates(for: age)
        if let base = defaults.first {
            let template = applyStyleVariation(base: base, style: style)
            previewBlocks = template.blocks
        } else {
            let fb = fallbackTemplate(style: style)
            previewBlocks = fb.blocks
        }
    }

    // MARK: - 🏷 Display Helpers

    /// Display name for the child — fallback to "your little one".
    var childDisplayName: String {
        let trimmed = childNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your little one" : trimmed
    }

    /// Template to apply at finish (nil = start with empty day).
    var selectedTemplateToApply: RoutineNestTemplate? {
        guard let style = selectedTemplateStyle else { return nil }
        return resolveTemplate()
    }

    /// Whether the current page allows forward navigation.
    var canProceed: Bool {
        switch currentLullaby {
        case .welcome:
            return true
        case .childProfile:
            return true // name is optional, age has default
        case .templatePick:
            return true  // empty day (nil) or template both valid
        case .reminderStyle:
            return true
        case .nestReady:
            return true
        }
    }

    /// Progress as a fraction (0...1).
    var nestProgress: Double {
        Double(currentLullaby.rawValue) / Double(OnboardingLullaby.allCases.count - 1)
    }

    /// Quick summary for the "ready" page.
    var onboardingSummary: String {
        let name = childDisplayName
        let age = selectedAgeGroup.displayTitle
        let start = selectedTemplateStyle?.displayTitle ?? "empty day"
        let reminder = selectedReminderStyle.displayTitle
        return "\(name) • \(age) • \(start) • \(reminder) notifications"
    }
}
