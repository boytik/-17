// DocumentFlowState.swift
// Little Days: Quiet Mind
// Flow controller: loading → webView / webViewEmpty / nativeApp

import Foundation
import UIKit
import Combine

// MARK: - Flow Phases

enum DocumentFlowPhase: Equatable {
    case loading
    case webView(url: URL)
    case webViewEmpty
    case nativeApp
}

// MARK: - Document Flow State

@MainActor
final class DocumentFlowState: ObservableObject {

    @Published var currentPhase: DocumentFlowPhase = .loading {
        didSet {
            print("[DocumentFlow] phase: \(phaseName(oldValue)) → \(phaseName(currentPhase))")
        }
    }

    private let service = DocumentValidationService()

    private func phaseName(_ p: DocumentFlowPhase) -> String {
        switch p {
        case .loading:           return "loading"
        case .webView(let url):  return "webView(\(url.absoluteString.prefix(60))...)"
        case .webViewEmpty:      return "webViewEmpty"
        case .nativeApp:         return "nativeApp"
        }
    }

    // MARK: - Run Flow

    func runFlow() {
        print("[DocumentFlow] runFlow started")

        if let choice = service.getFirstLaunchChoice() {
            if choice == "webView" {
                handleSavedWebViewChoice()
                return
            } else if choice == "nativeApp" {
                currentPhase = .nativeApp
                return
            }
        }

        runFirstLaunchValidations()
    }

    // MARK: - Saved Choice

    private func handleSavedWebViewChoice() {
        if let savedURL = service.getSavedURL() {
            currentPhase = .webView(url: savedURL)
            return
        }

        service.tryFallbackURL { [weak self] success, url in
            if success, let url = url {
                self?.currentPhase = .webView(url: url)
            } else {
                self?.currentPhase = .webViewEmpty
            }
        }
    }

    // MARK: - First Launch Validations

    private func runFirstLaunchValidations() {
        guard service.documentCheckDatePublic() else {
            service.setFirstLaunchChoice("nativeApp")
            currentPhase = .nativeApp
            return
        }

        guard UIDevice.current.userInterfaceIdiom != .pad else {
            service.setFirstLaunchChoice("nativeApp")
            currentPhase = .nativeApp
            return
        }

        service.checkInternetConnection { [weak self] hasInternet in
            guard let self else { return }
            guard hasInternet else {
                self.service.setFirstLaunchChoice("nativeApp")
                self.currentPhase = .nativeApp
                return
            }
            self.performServerRequest()
        }
    }

    private func performServerRequest() {
        service.requestServerURL { [weak self] success, finalURL in
            guard let self else { return }
            if success, let url = finalURL {
                self.service.setFirstLaunchChoice("webView")
                self.currentPhase = .webView(url: url)
            } else {
                self.service.setFirstLaunchChoice("nativeApp")
                self.currentPhase = .nativeApp
            }
        }
    }

    // MARK: - Fallback (called from WebView on error)

    func handleWebViewError() {
        service.tryFallbackURL { [weak self] success, url in
            if success, let url = url {
                self?.currentPhase = .webView(url: url)
            } else {
                self?.currentPhase = .webViewEmpty
            }
        }
    }

    func updateWebViewURL(_ url: URL) {
        currentPhase = .webView(url: url)
    }
}
