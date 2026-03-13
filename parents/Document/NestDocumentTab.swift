// NestDocumentTab.swift
// Little Days: Quiet Mind
// Document tab — full screen with own nav bar

import SwiftUI

// MARK: - 🌐 Nest Document Tab

struct NestDocumentTab: View {

    @State private var currentDestination: URL
    @State private var showError = false
    @State private var reloadKey = 0

    init() {
        _currentDestination = State(initialValue: DocumentValidationService.getSavedDestination() ?? DocumentValidationService.fallbackDestination)
    }

    var body: some View {
        NestDocumentWrapper(
            destination: currentDestination,
            onError: { showError = true },
            on404Detected: { loadFallback() }
        )
        .id(reloadKey)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Load Error", isPresented: $showError) {
            Button("Retry") { reloadCurrent() }
            Button("Use Fallback") { loadFallback() }
        } message: {
            Text("Could not load the page. Retry or use fallback.")
        }
    }

    private func reloadCurrent() {
        showError = false
        reloadKey += 1
    }

    private func loadFallback() {
        currentDestination = DocumentValidationService.fallbackDestination
        showError = false
    }
}
