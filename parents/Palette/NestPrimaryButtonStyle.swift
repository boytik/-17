//
//  NestPrimaryButtonStyle.swift
//  parents
//
//  Created by Евгений on 18.02.2026.
//

import SwiftUI
import Combine
/// Primary action button — gold on dark.
struct NestPrimaryButtonStyle: ButtonStyle {
    var isCompact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? NestTypography.sproutLabel : NestTypography.guardianHeadline)
            .foregroundColor(NestPalette.midnightNest)
            .padding(.horizontal, isCompact ? 20 : 32)
            .padding(.vertical, isCompact ? 12 : 16)
            .background(
                Capsule()
                    .fill(NestPalette.honeyGlow)
            )
            .overlay(
                Capsule()
                    .stroke(NestPalette.sunriseKiss.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Card press effect — scale on tap. No DragGesture, so ScrollView works in iOS 26+.
struct NestBlockCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
