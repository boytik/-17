// DocumentRootView.swift
// Little Days: Quiet Mind
// Root: Loading → WebView or Native App (per README flow)

import SwiftUI
import StoreKit

// MARK: - 🌐 Document Root View

struct DocumentRootView: View {

    @EnvironmentObject var flowState: DocumentFlowState
    @EnvironmentObject var nestMemory: NestMemory

    var body: some View {
        Group {
            switch flowState.currentPhase {
            case .loading:
                DocumentSplashScreenView()

            case .webView(let dest):
                NestDocumentRootContent(destination: dest)
                    .environmentObject(nestMemory)

            case .nativeApp:
                NativeAppRootView()
                    .environmentObject(nestMemory)
            }
        }
        .onAppear {
            if case .loading = flowState.currentPhase {
                print("[DocumentFlow] DocumentRootView onAppear, starting flow")
                flowState.runFlow()
            }
        }
    }
}

// MARK: - Phase Helpers

extension DocumentFlowPhase {
    var currentDestination: URL? {
        if case .webView(let dest) = self { return dest }
        return nil
    }
}

// MARK: - Nest Document Root Content

struct NestDocumentRootContent: View {

    let destination: URL
    @EnvironmentObject var nestMemory: NestMemory

    @State private var currentDestination: URL
    @State private var showError = false
    @State private var reloadKey = 0

    init(destination: URL) {
        self.destination = destination
        _currentDestination = State(initialValue: destination)
    }

    var body: some View {
        NestDocumentWrapper(
            destination: currentDestination,
            onError: { showError = true },
            on404Detected: { loadFallback() }
        )
        .id(reloadKey)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            NestAppDelegate.shared?.orientationLock = [.portrait, .landscapeLeft, .landscapeRight]
            requestReviewIfNeeded()
        }
        .alert("Load Error", isPresented: $showError) {
            Button("Retry") { reloadCurrent() }
            Button("Use Fallback") { loadFallback() }
        } message: {
            Text("Could not load the page. Retry or use fallback.")
        }
    }

    private func requestReviewIfNeeded() {
        let key = "nest_review_requested"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    private func reloadCurrent() {
        showError = false
        reloadKey += 1
    }

    private func loadFallback() {
        print("[DocumentFlow] NestDocumentRootContent loadFallback")
        currentDestination = DocumentValidationService.fallbackDestination
        showError = false
    }
}

// MARK: - Native App Root (portrait only)

struct NativeAppRootView: View {

    @EnvironmentObject var nestMemory: NestMemory

    var body: some View {
        ParentNestRootGate()
            .environmentObject(nestMemory)
            .onAppear {
                NestAppDelegate.shared?.orientationLock = .portrait
            }
    }
}
