// NestDocumentNavStore.swift
// Little Days: Quiet Mind
// Navigation state for document view (Back/Forward/Home/Reload)

import SwiftUI
import WebKit
import Combine

// MARK: - 🧭 Nest Document Nav Store

final class NestDocumentNavStore: ObservableObject {

    weak var documentView: WKWebView? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateNavigationState()
            }
        }
    }

    @Published var canGoBack = false
    @Published var canGoForward = false

    func goBack() { documentView?.goBack() }
    func goForward() { documentView?.goForward() }
    func reload() { documentView?.reload() }

    func goHome(destination: URL) {
        documentView?.load(URLRequest(url: destination))
    }

    func updateNavigationState() {
        canGoBack = documentView?.canGoBack ?? false
        canGoForward = documentView?.canGoForward ?? false
    }
}
