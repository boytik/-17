import SwiftUI

struct ShareSummaryNestSheet: View {

    @ObservedObject var brain: FamilyNestBrain
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Share Summary")
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
                .padding(.bottom, 8)

                // Scrollable content
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        Text("🌙 \(NestAppName.displayName) — Weekly Snapshot")
                            .font(NestTypography.sproutLabel)
                            .foregroundColor(NestPalette.honeyGlow)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(brain.shareSummaryText)
                            .font(NestTypography.lullabyBody)
                            .foregroundColor(NestPalette.parentVoice)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .fill(NestPalette.sleepyCharcoal)
                            .overlay(
                                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                                    .stroke(NestPalette.dreamlineDivider.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                }

                // Action buttons
                VStack(spacing: 12) {
                    ShareLink(item: brain.shareSummaryText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share with Partner")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NestPrimaryButtonStyle())

                    Button {
                        UIPasteboard.general.string = brain.shareSummaryText
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy to Clipboard")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NestGhostButtonStyle())
                }
                .padding(20)
                .background(NestPalette.midnightNest)
            }
        }
    }
}

