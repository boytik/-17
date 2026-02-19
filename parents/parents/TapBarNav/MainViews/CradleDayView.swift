

import SwiftUI

// MARK: - 📅 Cradle Day View — Main Timeline Screen

struct CradleDayView: View {

    @EnvironmentObject var nestMemory: NestMemory
    @StateObject private var brain = CradleDayBrain()

    @State private var showAddBlockNest = false
    @State private var selectedBlockForDetail: CradleBlock? = nil
    @State private var showDayNoteEditor = false
    @State private var showDuplicateConfirm = false
    @State private var showApplyTemplate = false
    @State private var showSaveTemplate = false

    var body: some View {
        ZStack {
            StarryNestBackground(particleCount: 30, showAura: true)

            // Entire day plan in one ScrollView — parent can scroll through the whole schedule
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    cradleDayHeader
                        .padding(.top, 8)

                    guardianProgressBar
                        .padding(.horizontal, NestDimensions.nestPadding)
                        .padding(.top, 8)

                    dayCompletionRing
                        .padding(.top, 12)

                    dayNoteCard
                        .padding(.top, 12)

                    if brain.sortedBlocks.isEmpty {
                        emptyNestState
                    } else {
                        timelineContent
                    }
                }
                .padding(.bottom, 100)
            }
            .refreshable {
                brain.loadDay(for: brain.currentDateKey)
            }
        }
        .sheet(isPresented: $showAddBlockNest) {
            AddBlockNestSheet(brain: brain)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedBlockForDetail) { block in
            BlockDetailNestSheet(block: block, brain: brain)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDayNoteEditor) {
            DayNoteNestSheet(brain: brain)
                .presentationDetents([.fraction(0.45), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showApplyTemplate) {
            ApplyTemplateNestSheet(brain: brain)
                .environmentObject(nestMemory)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSaveTemplate) {
            SaveTemplateNestSheet(brain: brain)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            brain.attachMemory(nestMemory)
            brain.loadToday()
        }
        .alert("Overwrite Tomorrow?", isPresented: $showDuplicateConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Overwrite", role: .destructive) {
                brain.duplicateToTomorrow()
            }
        } message: {
            Text("Tomorrow already has a plan. Copying will replace it.")
        }
    }

    // MARK: – Header

    private var cradleDayHeader: some View {
        HStack(alignment: .center) {
            // Date navigation
            Button {
                NestHaptic.selection()
                brain.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NestPalette.tenderWhisper)
                    .frame(width: NestDimensions.touchCradle, height: NestDimensions.touchCradle)
            }

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Text(brain.isToday ? "Today" : brain.displayDate)
                        .font(NestTypography.guardianHeadline)
                        .foregroundColor(NestPalette.parentVoice)
                    if !brain.isToday {
                        Button {
                            NestHaptic.selection()
                            brain.loadToday()
                        } label: {
                            Text("Today")
                                .font(NestTypography.tinyFootprint)
                                .foregroundColor(NestPalette.honeyGlow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(NestPalette.honeyGlow.opacity(0.2)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let profile = nestMemory.activeProfile {
                    Text("\(profile.avatarEmoji) \(profile.petName)")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)
                }
            }

            Button {
                NestHaptic.selection()
                brain.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NestPalette.tenderWhisper)
                    .frame(width: NestDimensions.touchCradle, height: NestDimensions.touchCradle)
            }

            Spacer()

            // Quick actions menu
            Menu {
                Button {
                    showAddBlockNest = true
                } label: {
                    Label("Add Block", systemImage: "plus.circle")
                }

                Button {
                    showDayNoteEditor = true
                } label: {
                    Label("Day Note", systemImage: "note.text")
                }

                Button {
                    brain.toggleQuietMode()
                } label: {
                    Label(
                        brain.isQuietMode ? "Quiet Mode On" : "Quiet Mode Off",
                        systemImage: brain.isQuietMode ? "moon.fill" : "moon"
                    )
                }

                Divider()

                Button {
                    showApplyTemplate = true
                } label: {
                    Label("Apply Template", systemImage: "square.stack.3d.up")
                }

                Button {
                    showSaveTemplate = true
                } label: {
                    Label("Save as Template", systemImage: "square.and.arrow.down")
                }
                .disabled(brain.totalCount == 0)

                Divider()

                Button {
                    if brain.tomorrowHasExistingBlocks() {
                        showDuplicateConfirm = true
                    } else {
                        brain.duplicateToTomorrow()
                    }
                } label: {
                    Label("Copy to Tomorrow", systemImage: "doc.on.doc")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(NestPalette.honeyGlow)
                    .frame(width: NestDimensions.touchCradle, height: NestDimensions.touchCradle)
            }
        }
        .padding(.horizontal, NestDimensions.nestPadding)
    }

    // MARK: – Guardian Progress Bar (XP + Streak)

    private var guardianProgressBar: some View {
        let gp = nestMemory.guardianProgress

        return HStack(spacing: 12) {
            // Level badge
            HStack(spacing: 5) {
                Text(gp.guardianLevel.emoji)
                    .font(.system(size: 16))

                Text("Lv.\(gp.guardianLevel.rawValue)")
                    .font(NestTypography.tinyFootprint)
                    .foregroundColor(NestPalette.honeyGlow)
            }

            // XP bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NestPalette.lullabyGray)
                        .frame(height: 6)

                    Capsule()
                        .fill(NestGradients.sunrisePath)
                        .frame(width: geo.size.width * gp.levelWarmth, height: 6)
                }
            }
            .frame(height: 6)

            // Stardust count
            HStack(spacing: 3) {
                Text("✦")
                    .font(.system(size: 10))
                    .foregroundColor(NestPalette.stardustReward)

                Text("\(gp.totalStardust)")
                    .font(NestTypography.tinyFootprint)
                    .foregroundColor(NestPalette.sunriseKiss)
            }

            // Streak
            if gp.currentStreak > 0 {
                HStack(spacing: 2) {
                    Text("🔥")
                        .font(.system(size: 10))

                    Text("\(gp.currentStreak)")
                        .font(NestTypography.tinyFootprint)
                        .foregroundColor(NestPalette.heartbeatStreak)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                .fill(NestPalette.sleepyCharcoal.opacity(0.7))
        )
    }

    // MARK: – Day Completion Ring

    private var dayCompletionRing: some View {
        HStack(spacing: 16) {
            // Mini ring
            ZStack {
                Circle()
                    .stroke(NestPalette.lullabyGray, lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: brain.completionFraction)
                    .stroke(
                        NestPalette.honeyGlow,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: brain.completionFraction)

                Text("\(brain.doneCount)")
                    .font(NestTypography.tinyFootprint)
                    .foregroundColor(NestPalette.honeyGlow)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(brain.doneCount) of \(brain.totalCount) blocks done")
                    .font(NestTypography.sproutLabel)
                    .foregroundColor(NestPalette.parentVoice)

                Text(brain.completionEncouragement)
                    .font(NestTypography.whisperCaption)
                    .foregroundColor(NestPalette.tenderWhisper)
            }

            Spacer()

            // Today XP earned
            VStack(spacing: 2) {
                Text("+\(brain.todayXP)")
                    .font(NestTypography.sproutLabel)
                    .foregroundColor(NestPalette.stardustReward)

                Text("stardust")
                    .font(NestTypography.tinyFootprint)
                    .foregroundColor(NestPalette.drowsyHint)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                .fill(NestPalette.sleepyCharcoal.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                        .stroke(NestPalette.dreamlineDivider.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, NestDimensions.nestPadding)
    }

    // MARK: – Day Note Card

    private var dayNoteCard: some View {
        Button {
            showDayNoteEditor = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 18))
                    .foregroundColor(NestPalette.honeyGlow.opacity(0.8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Day Note")
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)

                    if brain.dayNote.isEmpty {
                        Text("Tap to add a note for this day")
                            .font(NestTypography.whisperCaption)
                            .foregroundColor(NestPalette.drowsyHint)
                            .italic()
                    } else {
                        Text(brain.dayNote)
                            .font(NestTypography.lullabyBody)
                            .foregroundColor(NestPalette.tenderWhisper)
                            .multilineTextAlignment(.leading)
                            .lineLimit(4)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(NestPalette.drowsyHint)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .fill(NestPalette.sleepyCharcoal.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .stroke(NestPalette.dreamlineDivider.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, NestDimensions.nestPadding)
    }

    // MARK: – Timeline Content (inside main ScrollView)

    private var timelineContent: some View {
        LazyVStack(spacing: NestDimensions.blockGap) {
            if brain.isToday && !brain.sortedBlocks.isEmpty {
                timeIndicatorLine
            }

            ForEach(Array(brain.sortedBlocks.enumerated()), id: \.element.id) { index, block in
                CradleBlockCard(
                    block: block,
                    isCurrentTimeSlot: brain.isCurrentTimeSlot(block),
                    onQuickDone: {
                        brain.quickMarkDone(blockId: block.id)
                    },
                    onTap: {
                        selectedBlockForDetail = block
                    },
                    onMove: { delta in brain.moveBlock(blockId: block.id, byMinutes: delta) },
                    onRemove: { brain.removeBlock(blockId: block.id) }
                )
                .nestFadeIn(delay: Double(index) * 0.05)
            }

            Button {
                showAddBlockNest = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Block")
                        .font(NestTypography.sproutLabel)
                }
                .foregroundColor(NestPalette.honeyGlow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                        .stroke(NestPalette.honeyGlow.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                )
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, NestDimensions.nestPadding)
        .padding(.top, 12)
    }

    // MARK: – Time Indicator Line

    private var timeIndicatorLine: some View {
        let now = NestDateHelper.minutesNow()
        let isVisible = now >= (brain.sortedBlocks.first?.startFeather ?? 0) &&
                       now <= (brain.sortedBlocks.last?.endFeather ?? 1440)

        return Group {
            if isVisible {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(NestPalette.honeyGlow)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                    Text(NestDateHelper.timeString(from: now))
                        .font(NestTypography.tinyFootprint)
                        .foregroundColor(NestPalette.honeyGlow)
                    Rectangle()
                        .fill(NestPalette.honeyGlow)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: – Empty State

    private var emptyNestState: some View {
        VStack(spacing: 20) {
            Text("🪹")
                .font(.system(size: 64))
                .nestFloating(amplitude: 5, duration: 3)

            Text("The nest is empty")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            Text("Add your first block to start the day")
                .font(NestTypography.lullabyBody)
                .foregroundColor(NestPalette.tenderWhisper)
                .multilineTextAlignment(.center)

            Button {
                showAddBlockNest = true
            } label: {
                Text("Add First Block")
            }
            .buttonStyle(NestPrimaryButtonStyle())
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

// MARK: - 🃏 Cradle Block Card

struct CradleBlockCard: View {

    let block: CradleBlock
    var isCurrentTimeSlot: Bool = false
    var onQuickDone: () -> Void
    var onTap: () -> Void
    var onMove: ((Int) -> Void)?
    var onRemove: (() -> Void)?

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Left: status stripe
                statusStripe

                // Icon
                blockIconCircle

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(block.displayTitle)
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(NestPalette.parentVoice)

                        if block.moveCount > 0 {
                            Text("↻\(block.moveCount)")
                                .font(NestTypography.tinyFootprint)
                                .foregroundColor(NestPalette.driftingCloud)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(NestPalette.driftingCloud.opacity(0.15))
                                )
                        }
                    }

                    Text(block.timeRangeLabel)
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)

                    if !block.tinyNote.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.system(size: 10))
                                .foregroundColor(NestPalette.drowsyHint)
                            Text(block.tinyNote)
                                .font(NestTypography.tinyFootprint)
                                .foregroundColor(NestPalette.drowsyHint)
                                .lineLimit(3)
                        }
                    }
                }

                Spacer()

                // Right: quick action or mood
                rightAccessory
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(cardBackground)
        }
        .buttonStyle(NestBlockCardButtonStyle())
        .contextMenu {
            if let onMove = onMove, block.completionMark == .pending {
                Button {
                    onMove(15)
                } label: {
                    Label("Move +15 min", systemImage: "arrow.right")
                }
                Button {
                    onMove(30)
                } label: {
                    Label("Move +30 min", systemImage: "arrow.right")
                }
            }
            Button {
                onTap()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            if let onRemove = onRemove {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: – Status Stripe

    private var statusStripe: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(statusColor)
            .frame(width: 4, height: 44)
    }

    // MARK: – Icon Circle

    private var blockIconCircle: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: block.blockKind.sfIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(statusColor)
        }
    }

    // MARK: – Right Accessory

    @ViewBuilder
    private var rightAccessory: some View {
        switch block.completionMark {
        case .pending:
            Button {
                onQuickDone()
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 26))
                    .foregroundColor(NestPalette.calmBreath.opacity(0.6))
                    .frame(width: NestDimensions.touchCradle, height: NestDimensions.touchCradle)
            }
            .buttonStyle(.plain)

        case .done:
            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(NestPalette.calmBreath)

                if let mood = block.moodStamp {
                    Text(mood.emoji)
                        .font(.system(size: 12))
                }

                Text("+\(block.blockKind.sproutXP)✦")
                    .font(NestTypography.tinyFootprint)
                    .foregroundColor(NestPalette.stardustReward)
            }

        case .moved:
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(NestPalette.driftingCloud)

        case .skipped:
            Image(systemName: "xmark.circle")
                .font(.system(size: 22))
                .foregroundColor(NestPalette.gentleBlush.opacity(0.7))
        }
    }

    // MARK: – Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
            .fill(NestPalette.sleepyCharcoal)
            .overlay(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .stroke(
                        isCurrentTimeSlot
                            ? NestPalette.honeyGlow.opacity(0.5)
                            : NestPalette.dreamlineDivider.opacity(0.3),
                        lineWidth: isCurrentTimeSlot ? 1.5 : 1
                    )
            )
            .shadow(
                color: isCurrentTimeSlot ? NestPalette.honeyGlow.opacity(0.1) : .clear,
                radius: isCurrentTimeSlot ? 8 : 0
            )
    }

    // MARK: – Status Color

    private var statusColor: Color {
        switch block.completionMark {
        case .pending:  return isCurrentTimeSlot ? NestPalette.playfulSunbeam : NestPalette.drowsyHint
        case .done:     return NestPalette.calmBreath
        case .moved:    return NestPalette.driftingCloud
        case .skipped:  return NestPalette.gentleBlush
        }
    }
}

// MARK: - ➕ Add Block Sheet

struct AddBlockNestSheet: View {

    @ObservedObject var brain: CradleDayBrain
    @Environment(\.dismiss) private var dismiss

    @State private var selectedKind: BlockKind = .feedingNest
    @State private var customTitleText: String = ""
    @State private var startHour: Int = 9
    @State private var startMinute: Int = 0
    @State private var durationMinutes: Int = 60
    @State private var showOverlapWarning = false

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerBar
                    blockNameSection
                    blockKindGrid
                    timePickerSection
                    durationSection

                    if showOverlapWarning {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(NestPalette.gentleBlush)
                            Text("This time overlaps with existing blocks")
                                .font(NestTypography.lullabyBody)
                                .foregroundColor(NestPalette.gentleBlush)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                                .fill(NestPalette.gentleBlush.opacity(0.15))
                        )
                    }

                    Button {
                        let start = startHour * 60 + startMinute
                        if brain.wouldOverlap(startMinute: start, durationMinutes: durationMinutes) {
                            showOverlapWarning = true
                            NestHaptic.notification(.warning)
                        } else if brain.addBlock(
                            kind: selectedKind,
                            startMinute: start,
                            durationMinutes: durationMinutes,
                            customTitle: customTitleText.isEmpty ? nil : customTitleText
                        ) {
                            NestHaptic.impact(.light)
                            dismiss()
                        }
                    } label: {
                        Text("Add to Day")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NestPrimaryButtonStyle())
                    .padding(.horizontal, 8)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: startHour) { _ in showOverlapWarning = false }
            .onChange(of: startMinute) { _ in showOverlapWarning = false }
            .onChange(of: durationMinutes) { _ in showOverlapWarning = false }
        }
    }

    private var headerBar: some View {
        HStack {
            Text("New Block")
                .font(NestTypography.guardianHeadline)
                .foregroundColor(NestPalette.parentVoice)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(NestPalette.drowsyHint)
            }
        }
    }

    private var blockNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Block name (optional)")
                .font(NestTypography.sproutLabel)
                .foregroundColor(NestPalette.tenderWhisper)

            TextField("", text: $customTitleText)
                .placeholder(when: customTitleText.isEmpty) {
                    Text("e.g. Morning nap, Lunch")
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
        }
    }

    private var blockKindGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 12) {
            ForEach(BlockKind.allCases) { kind in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedKind = kind
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(kind.emoji)
                            .font(.system(size: 28))

                        Text(kind.displayTitle)
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(
                                selectedKind == kind
                                ? NestPalette.midnightNest
                                : NestPalette.tenderWhisper
                            )
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                            .fill(
                                selectedKind == kind
                                ? NestPalette.honeyGlow
                                : NestPalette.sleepyCharcoal
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                            .stroke(
                                selectedKind == kind
                                ? NestPalette.sunriseKiss.opacity(0.5)
                                : NestPalette.dreamlineDivider.opacity(0.4),
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }

    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Time")
                .font(NestTypography.sproutLabel)
                .foregroundColor(NestPalette.tenderWhisper)

            HStack(spacing: 16) {
                Picker("Hour", selection: $startHour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h))
                            .foregroundColor(NestPalette.parentVoice)
                            .tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70, height: 100)
                .clipped()

                Text(":")
                    .font(NestTypography.guardianHeadline)
                    .foregroundColor(NestPalette.honeyGlow)

                Picker("Minute", selection: $startMinute) {
                    ForEach([0, 15, 30, 45], id: \.self) { m in
                        Text(String(format: "%02d", m))
                            .foregroundColor(NestPalette.parentVoice)
                            .tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70, height: 100)
                .clipped()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration: \(durationMinutes) min")
                .font(NestTypography.sproutLabel)
                .foregroundColor(NestPalette.tenderWhisper)

            HStack(spacing: 10) {
                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { dur in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            durationMinutes = dur
                        }
                    } label: {
                        Text("\(dur)")
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(
                                durationMinutes == dur
                                ? NestPalette.midnightNest
                                : NestPalette.tenderWhisper
                            )
                            .frame(width: 42, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        durationMinutes == dur
                                        ? NestPalette.honeyGlow
                                        : NestPalette.lullabyGray
                                    )
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - 📋 Block Detail Sheet

struct BlockDetailNestSheet: View {

    let block: CradleBlock
    @ObservedObject var brain: CradleDayBrain
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood: MoodStamp? = nil
    @State private var noteText: String = ""
    @State private var customTitleText: String = ""

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text(block.blockKind.emoji)
                            .font(.system(size: 32))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.timeRangeLabel)
                                .font(NestTypography.whisperCaption)
                                .foregroundColor(NestPalette.tenderWhisper)
                        }

                        Spacer()

                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(NestPalette.drowsyHint)
                        }
                    }

                    // Editable block name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Block name")
                            .font(NestTypography.whisperCaption)
                            .foregroundColor(NestPalette.tenderWhisper)

                        TextField("", text: $customTitleText)
                            .placeholder(when: customTitleText.isEmpty) {
                                Text(block.blockKind.displayTitle)
                                    .foregroundColor(NestPalette.drowsyHint)
                            }
                            .font(NestTypography.guardianHeadline)
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
                            .onSubmit {
                                brain.updateBlockCustomTitle(blockId: block.id, customTitle: customTitleText)
                            }
                    }

                    // XP reward preview
                    HStack {
                        Text("Reward: +\(block.blockKind.sproutXP) ✦ stardust")
                            .font(NestTypography.whisperCaption)
                            .foregroundColor(NestPalette.stardustReward)

                        Spacer()

                        Text("Status: \(block.completionMark.displayLabel)")
                            .font(NestTypography.whisperCaption)
                            .foregroundColor(NestPalette.tenderWhisper)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(NestPalette.sleepyCharcoal)
                    )

                    Divider().overlay(NestPalette.dreamlineDivider)

                    // Mark actions
                    Text("Mark As")
                        .font(NestTypography.sproutLabel)
                        .foregroundColor(NestPalette.parentVoice)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        markButton(mark: .done, icon: "checkmark.circle.fill", color: NestPalette.calmBreath, label: "Done")
                        markButton(mark: .moved, icon: "arrow.right.circle.fill", color: NestPalette.driftingCloud, label: "Moved")
                        markButton(mark: .skipped, icon: "xmark.circle", color: NestPalette.gentleBlush, label: "Skip")
                    }

                    // Mood picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How did it go?")
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(NestPalette.parentVoice)

                        HStack(spacing: 16) {
                            ForEach(MoodStamp.allCases, id: \.rawValue) { mood in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedMood = mood
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(mood.emoji)
                                            .font(.system(size: 32))
                                            .scaleEffect(selectedMood == mood ? 1.2 : 1.0)

                                        Text(mood.label)
                                            .font(NestTypography.tinyFootprint)
                                            .foregroundColor(
                                                selectedMood == mood
                                                ? NestPalette.honeyGlow
                                                : NestPalette.tenderWhisper
                                            )
                                    }
                                    .frame(width: 70, height: 64)
                                    .background(
                                        RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                                            .fill(
                                                selectedMood == mood
                                                ? NestPalette.honeyGlow.opacity(0.12)
                                                : NestPalette.sleepyCharcoal
                                            )
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Note")
                            .font(NestTypography.whisperCaption)
                            .foregroundColor(NestPalette.tenderWhisper)

                        TextField("", text: $noteText)
                            .placeholder(when: noteText.isEmpty) {
                                Text("Optional — what happened?")
                                    .foregroundColor(NestPalette.drowsyHint)
                            }
                            .font(NestTypography.lullabyBody)
                            .foregroundColor(NestPalette.parentVoice)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                                    .fill(NestPalette.sleepyCharcoal)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NestDimensions.pebbleCorner)
                                            .stroke(NestPalette.dreamlineDivider, lineWidth: 1)
                                    )
                            )
                    }

                    // Delete block
                    Button(role: .destructive) {
                        brain.removeBlock(blockId: block.id)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove Block")
                        }
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.gentleBlush)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            selectedMood = block.moodStamp
            noteText = block.tinyNote
            customTitleText = block.customTitle ?? ""
        }
        .onDisappear {
            brain.updateBlockCustomTitle(blockId: block.id, customTitle: customTitleText)
        }
    }

    private func markButton(mark: CompletionMark, icon: String, color: Color, label: String) -> some View {
        Button {
            brain.markBlock(blockId: block.id, status: mark, mood: selectedMood, note: noteText, customTitle: customTitleText.isEmpty ? nil : customTitleText)
            dismiss()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)

                Text(label)
                    .font(NestTypography.tinyFootprint)
                    .foregroundColor(NestPalette.tenderWhisper)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

