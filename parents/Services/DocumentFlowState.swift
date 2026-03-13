// DocumentFlowState.swift
// Little Days: Quiet Mind
// Flow controller: loading → webView or nativeApp

import SwiftUI
import Combine

// MARK: - 🌐 Document Flow State

enum DocumentFlowPhase: Equatable {
    case loading
    case webView(destination: URL)
    case nativeApp
}

final class DocumentFlowState: ObservableObject {

    let objectWillChange = ObservableObjectPublisher()

    var currentPhase: DocumentFlowPhase = .loading {
        willSet { objectWillChange.send() }
    }

    func runFlow() {
        print("[DocumentFlow] runFlow started")
        currentPhase = .loading

        if let choice = DocumentValidationService.getFirstLaunchChoice() {
            print("[DocumentFlow] firstLaunchChoice = \(choice)")
            if choice == "webView" {
                let destination = DocumentValidationService.getSavedDestination()
                    ?? DocumentValidationService.fallbackDestination
                print("[DocumentFlow] → webView, destination: \(destination.absoluteString)")
                currentPhase = .webView(destination: destination)
                return
            }
            if choice == "nativeApp" {
                print("[DocumentFlow] → nativeApp")
                currentPhase = .nativeApp
                return
            }
        }

        print("[DocumentFlow] first launch, running validations...")
        DocumentValidationService.runFirstLaunchValidations { [weak self] success, destination in
            if success, let dest = destination {
                print("[DocumentFlow] validations OK → webView, destination: \(dest.absoluteString)")
                self?.currentPhase = .webView(destination: dest)
            } else {
                print("[DocumentFlow] validations FAIL → nativeApp")
                self?.currentPhase = .nativeApp
            }
        }
    }
}
