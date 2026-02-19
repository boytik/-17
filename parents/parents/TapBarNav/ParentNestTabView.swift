// ParentNestTabView.swift
// с17 — Daily Routine Without Stress
// Main tab navigation — 3 tabs: Day, Insights, Settings

import SwiftUI

// MARK: - 🏠 Parent Nest Tab View — Main Container

struct ParentNestTabView: View {

    @EnvironmentObject var nestMemory: NestMemory

    @State private var selectedNestTab: NestTab = .cradleDay
    @State private var tabBounce: NestTab? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            tabContentLayer
                .ignoresSafeArea(.keyboard, edges: .bottom)

            // Custom tab bar
            nestTabBar
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: – Tab Content

    private var tabContentLayer: some View {
        ZStack {
            switch selectedNestTab {
            case .cradleDay:
                CradleDayView()
                    .environmentObject(nestMemory)
                    .transition(.opacity)

            case .growthGarden:
                GrowthGardenView()
                    .environmentObject(nestMemory)
                    .transition(.opacity)

            case .familyNest:
                FamilyNestView()
                    .environmentObject(nestMemory)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedNestTab)
    }

    // MARK: – Custom Tab Bar

    private var nestTabBar: some View {
        HStack(spacing: 0) {
            ForEach(NestTab.allCases, id: \.self) { tab in
                tabBarButton(for: tab)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, bottomSafePadding)
        .background(
            nestTabBarBackground
        )
    }

    private func tabBarButton(for tab: NestTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedNestTab = tab
                tabBounce = tab
            }
            // Reset bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                tabBounce = nil
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Glow behind selected icon
                    if selectedNestTab == tab {
                        Circle()
                            .fill(NestPalette.honeyGlow.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .blur(radius: 4)
                    }

                    Image(systemName: tab.sfIcon(isSelected: selectedNestTab == tab))
                        .font(.system(size: 20, weight: selectedNestTab == tab ? .semibold : .regular))
                        .foregroundColor(
                            selectedNestTab == tab
                            ? NestPalette.honeyGlow
                            : NestPalette.drowsyHint
                        )
                        .scaleEffect(tabBounce == tab ? 1.2 : 1.0)
                }
                .frame(height: 28)

                Text(tab.displayLabel)
                    .font(NestTypography.nestTabLabel)
                    .foregroundColor(
                        selectedNestTab == tab
                        ? NestPalette.honeyGlow
                        : NestPalette.drowsyHint
                    )

                // Active indicator dot
                Circle()
                    .fill(
                        selectedNestTab == tab
                        ? NestPalette.honeyGlow
                        : Color.clear
                    )
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: – Tab Bar Background

    private var nestTabBarBackground: some View {
        ZStack(alignment: .top) {
            // Blur-like dark surface
            Rectangle()
                .fill(NestPalette.midnightNest.opacity(0.92))

            // Top separator with gold hint
            LinearGradient(
                colors: [
                    NestPalette.honeyGlow.opacity(0.15),
                    NestPalette.honeyGlow.opacity(0.03),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 1)

            // Subtle inner glow
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            NestPalette.sleepyCharcoal.opacity(0.4),
                            NestPalette.midnightNest.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 12)
        }
    }

    // MARK: – Safe Area Helper

    private var bottomSafePadding: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let bottom = windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
        return max(bottom, 16)
    }
}

// MARK: - 📑 Nest Tab Enum

enum NestTab: Int, CaseIterable, Hashable {
    case cradleDay     = 0
    case growthGarden  = 1
    case familyNest    = 2

    var displayLabel: String {
        switch self {
        case .cradleDay:    return "Day"
        case .growthGarden: return "Growth"
        case .familyNest:   return "Nest"
        }
    }

    func sfIcon(isSelected: Bool) -> String {
        switch self {
        case .cradleDay:
            return isSelected ? "calendar.circle.fill" : "calendar.circle"
        case .growthGarden:
            return isSelected ? "chart.bar.fill" : "chart.bar"
        case .familyNest:
            return isSelected ? "gearshape.fill" : "gearshape"
        }
    }
}

// MARK: - 🎯 Tab Bar Visibility Key

/// Environment key to allow child views to hide the tab bar if needed.
private struct NestTabBarVisibleKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

extension EnvironmentValues {
    var nestTabBarVisible: Binding<Bool> {
        get { self[NestTabBarVisibleKey.self] }
        set { self[NestTabBarVisibleKey.self] = newValue }
    }
}

// MARK: - Preview

#if DEBUG
struct ParentNestTabView_Previews: PreviewProvider {
    static var previews: some View {
        ParentNestTabView()
            .environmentObject(NestMemory.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
