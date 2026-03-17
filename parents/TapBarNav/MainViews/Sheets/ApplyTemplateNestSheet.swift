import SwiftUI

struct ApplyTemplateNestSheet: View {

    @ObservedObject var brain: CradleDayBrain
    @EnvironmentObject var nestMemory: NestMemory
    @Environment(\.dismiss) private var dismiss

    @State private var templateToApply: RoutineNestTemplate?
    @State private var showReplaceConfirm = false

    private var allTemplates: [RoutineNestTemplate] {
        guard let profile = nestMemory.activeProfile else { return [] }
        let builtIn = NestTemplateSeedlings.defaultTemplates(for: profile.ageNestGroup)
        let saved = nestMemory.loadAllTemplates()
        return builtIn + saved
    }

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(NSLocalizedString("Apply Template", comment: ""))
                        .font(NestTypography.guardianHeadline)
                        .foregroundColor(NestPalette.parentVoice)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(NestPalette.drowsyHint)
                    }
                }
                .padding(20)

                if allTemplates.isEmpty {
                    VStack(spacing: 16) {
                        Text(NSLocalizedString("No templates yet", comment: ""))
                            .font(NestTypography.lullabyBody)
                            .foregroundColor(NestPalette.tenderWhisper)
                        Text(NSLocalizedString("Save your current day as a template to reuse it", comment: ""))
                            .font(NestTypography.whisperCaption)
                            .foregroundColor(NestPalette.drowsyHint)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(allTemplates) { template in
                                Button {
                                    if brain.totalCount > 0 {
                                        templateToApply = template
                                        showReplaceConfirm = true
                                    } else {
                                        brain.applyTemplate(template)
                                        dismiss()
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        Text(template.style.emoji)
                                            .font(.system(size: 28))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.title)
                                                .font(NestTypography.sproutLabel)
                                                .foregroundColor(NestPalette.parentVoice)
                                            Text(String(format: NSLocalizedString("%lld blocks • %@", comment: ""), template.blocks.count, template.ageGroup.shortLabel))
                                                .font(NestTypography.tinyFootprint)
                                                .foregroundColor(NestPalette.tenderWhisper)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(NestPalette.drowsyHint)
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                                            .fill(NestPalette.sleepyCharcoal)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .alert(NSLocalizedString("Replace blocks?", comment: ""), isPresented: $showReplaceConfirm) {
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                templateToApply = nil
            }
            Button(NSLocalizedString("Replace", comment: ""), role: .destructive) {
                if let template = templateToApply {
                    brain.applyTemplate(template)
                    dismiss()
                }
                templateToApply = nil
            }
        } message: {
            Text(String(format: NSLocalizedString("This will replace your current %lld blocks with the template.", comment: ""), brain.totalCount))
        }
    }
}
