// ParentNestApp.swift
// с17 — Daily Routine Without Stress
// App entry point — @main

import SwiftUI

// MARK: - 🚀 Parent Nest App — Entry Point

@main
struct ParentNestApp: App {

    @UIApplicationDelegateAdaptor(NestAppDelegate.self) var appDelegate
    @StateObject private var flowState = DocumentFlowState()
    @StateObject private var nestMemory = NestMemory.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureNestAppearance()
    }

    var body: some Scene {
        WindowGroup {
            DocumentRootView()
                .environmentObject(flowState)
                .environmentObject(nestMemory)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                nestMemory.rescheduleTodayNotificationsIfNeeded()
            }
        }
    }

    // MARK: – Global Appearance

    /// Configures UIKit-level appearance to match the dark premium theme.
    private func configureNestAppearance() {

        // Tab bar (fallback in case native TabView leaks through)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(NestPalette.midnightNest)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(NestPalette.midnightNest)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(NestPalette.parentVoice)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(NestPalette.parentVoice)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(NestPalette.honeyGlow)

        // Scroll indicators
        UIScrollView.appearance().indicatorStyle = .white

        // Picker wheel text color
        UIPickerView.appearance().tintColor = UIColor(NestPalette.honeyGlow)

        // Text views (TextEditor background)
        UITextView.appearance().backgroundColor = .clear

        // Sheet presentation — darker grabber
        if #available(iOS 16.0, *) {
            // presentationDragIndicator is set per-sheet in SwiftUI
        }
    }
}
