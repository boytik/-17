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
                    Text("Save as Template")
                        .font(NestTypography.guardianHeadline)
                        .foregroundColor(NestPalette.parentVoice)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(NestPalette.drowsyHint)
                    }
                }

                Text("Save your current \(brain.totalCount) blocks as a reusable template")
                    .font(NestTypography.lullabyBody)
                    .foregroundColor(NestPalette.tenderWhisper)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Template name")
                        .font(NestTypography.whisperCaption)
                        .foregroundColor(NestPalette.tenderWhisper)

                    TextField("", text: $templateTitle)
                        .placeholder(when: templateTitle.isEmpty) {
                            Text("e.g. Weekday routine")
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
                    Text("Save Template")
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
