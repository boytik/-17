// NestDocumentNavBar.swift
// Little Days: Quiet Mind
// 4-button navigation bar (Back, Forward, Home, Reload)

import SwiftUI
import Combine

// MARK: - 🧭 Nest Document Nav Bar — 4 Buttons

private let navButtonSize: CGFloat = 44
private let navBarWidth: CGFloat = 52

struct NestDocumentNavBar: View {

    @ObservedObject var navStore: NestDocumentNavStore
    let homeDestination: URL?
    var isVertical: Bool = false

    var body: some View {
        if isVertical {
            VStack(spacing: 8) {
                navButton(icon: "chevron.left", enabled: navStore.canGoBack) { navStore.goBack() }
                navButton(icon: "chevron.right", enabled: navStore.canGoForward) { navStore.goForward() }
                navButton(icon: "house.fill", enabled: homeDestination != nil) {
                    if let dest = homeDestination { navStore.goHome(destination: dest) }
                }
                navButton(icon: "arrow.clockwise", enabled: true) { navStore.reload() }
            }
            .frame(width: navBarWidth)
            .padding(.vertical, 12)
        } else {
            HStack(spacing: 0) {
                navButton(icon: "chevron.left", enabled: navStore.canGoBack) { navStore.goBack() }
                navButton(icon: "chevron.right", enabled: navStore.canGoForward) { navStore.goForward() }
                navButton(icon: "house.fill", enabled: homeDestination != nil) {
                    if let dest = homeDestination { navStore.goHome(destination: dest) }
                }
                navButton(icon: "arrow.clockwise", enabled: true) { navStore.reload() }
            }
            .frame(height: navButtonSize)
            .padding(.horizontal, 8)
        }
    }

    private func navButton(
        icon: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(enabled ? NestPalette.honeyGlow : NestPalette.drowsyHint)
                .frame(width: navButtonSize, height: navButtonSize)
        }
        .disabled(!enabled)
    }
}
