// DocumentRootView.swift
// Little Days: Quiet Mind
// Root: Loading → WebView or Native App (per README flow)

import SwiftUI
import StoreKit

// MARK: - Document Root View

struct DocumentRootView: View {

    @EnvironmentObject var flowState: DocumentFlowState
    @EnvironmentObject var nestMemory: NestMemory

    @AppStorage("nest_review_requested") private var hasShownRatingPrompt = false

    var body: some View {
        ZStack {
            switch flowState.currentPhase {
            case .loading:
                DocumentSplashScreenView()

            case .webView(let url):
                NestDocumentRootContent(url: url)
                    .environmentObject(nestMemory)
                    .id(url.absoluteString)
                    .onAppear {
                        showAppRatingIfNeeded()
                        NestAppDelegate.shared?.orientationLock = [.portrait, .landscapeLeft, .landscapeRight]
                    }

            case .webViewEmpty:
                NestDocumentRootContent(url: URL(string: "about:blank")!)
                    .environmentObject(nestMemory)
                    .onAppear {
                        NestAppDelegate.shared?.orientationLock = [.portrait, .landscapeLeft, .landscapeRight]
                    }

            case .nativeApp:
                NativeAppRootView()
                    .environmentObject(nestMemory)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: flowState.currentPhase)
        .onAppear {
            if case .loading = flowState.currentPhase {
                flowState.runFlow()
            }
        }
    }

    private func showAppRatingIfNeeded() {
        guard !hasShownRatingPrompt else { return }
        hasShownRatingPrompt = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}

// MARK: - Phase Helpers

extension DocumentFlowPhase {
    var currentURL: URL? {
        if case .webView(let url) = self { return url }
        return nil
    }
}

// MARK: - Nest Document Root Content

struct NestDocumentRootContent: View {

    let url: URL
    @EnvironmentObject var nestMemory: NestMemory
    @EnvironmentObject var flowState: DocumentFlowState

    var body: some View {
        NestDocumentWrapper(
            destination: url,
            onError: { flowState.handleWebViewError() },
            on404Detected: { flowState.handleWebViewError() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
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
