

import SwiftUI
/// Premium card style — dark surface with subtle gold edge.
struct NestCardModifier: ViewModifier {
    var isElevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(NestDimensions.cradlePadding)
            .background(
                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                    .fill(NestPalette.sleepyCharcoal)
                    .overlay(
                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                            .stroke(
                                isElevated
                                    ? NestPalette.honeyGlow.opacity(0.3)
                                    : NestPalette.dreamlineDivider.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isElevated ? NestPalette.honeyGlow.opacity(0.12) : .clear,
                radius: isElevated ? NestDimensions.liftedShadow : 0,
                x: 0,
                y: isElevated ? 4 : 0
            )
    }
}
