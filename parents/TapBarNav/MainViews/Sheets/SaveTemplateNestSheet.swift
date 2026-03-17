import SwiftUI

struct SaveTemplateNestSheet: View {

    @ObservedObject var brain: CradleDayBrain
    @Environment(\.dismiss) private var dismiss

    @State private var templateTitle: String = "My Routine"

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text(NSLocalizedString("Save as Template", comment: ""))
                        .font(NestTypography.guardianHeadline)
                        .foregroundColor(NestPalette.parentVoice)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(NestPalette.drowsyHint)
                    }
                }

                Text(String(format: NSLocalizedString("Save your current %lld blocks as a reusable template", comment: ""), brain.totalCount))
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)

                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Template name", comment: ""))
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)

                    TextField("", text: $templateTitle)
                        .placeholder(when: templateTitle.isEmpty) {
                            Text(NSLocalizedString("e.g. Weekday routine", comment: ""))
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

                Button {
                    let title = templateTitle.trimmingCharacters(in: .whitespaces)
                    let name = title.isEmpty ? "My Routine" : title
                    _ = brain.createTemplateFromCurrentDay(title: name)
                    dismiss()
                } label: {
                    Text(NSLocalizedString("Save Template", comment: ""))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(NestPrimaryButtonStyle())
                .disabled(brain.totalCount == 0)

                Spacer()
            }
            .padding(20)
        }
    }
}
