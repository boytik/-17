// NestDocumentPanel.swift
// Little Days: Quiet Mind
// Document view wrapper with KVO for navigation state

import SwiftUI
import WebKit

// MARK: - 🌐 Nest Document Panel

struct NestDocumentPanel: UIViewRepresentable {

    let destination: URL
    @ObservedObject var navigationStore: NestDocumentNavStore
    let onError: () -> Void
    let on404Detected: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            navigationStore: navigationStore,
            onError: onError,
            on404Detected: on404Detected
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Persistent data store — cookies, localStorage, sessionStorage survive app restarts.
        // Using .default() singleton ensures cookies are shared across all WebView instances
        // (e.g. after fallback URL switch) and are never lost between sessions.
        config.websiteDataStore = WKWebsiteDataStore.default()

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator

        // Sync any cookies set via URLSession / HTTPCookieStorage into WKWebView's cookie store.
        // This covers cookies received during the server validation request in DocumentValidationService.
        syncHTTPCookiesToWebView(cookieStore: config.websiteDataStore.httpCookieStore)

        view.allowsBackForwardNavigationGestures = true
        view.isOpaque = true
        view.backgroundColor = .white
        // Prevent WKWebView from automatically adding safe area insets to its scroll view.
        // Safe area is managed at the layout level (NestDocumentContainer / NestDocumentHostingController).
        view.scrollView.contentInsetAdjustmentBehavior = .never

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh), for: .valueChanged)
        view.scrollView.bounces = true
        view.scrollView.refreshControl = refreshControl

        navigationStore.documentView = view
        context.coordinator.setupNavigationObservers(for: view, store: navigationStore)

        print("[DocumentFlow] NestDocumentPanel loading: \(destination.absoluteString)")
        view.load(URLRequest(url: destination))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Cookie Sync

    /// Copies cookies from the system HTTPCookieStorage into WKWebView's persistent cookie store.
    /// Called once when the WebView is created so that cookies set during URLSession requests
    /// (e.g. server validation) are available to the page immediately.
    private func syncHTTPCookiesToWebView(cookieStore: WKHTTPCookieStore) {
        guard let cookies = HTTPCookieStorage.shared.cookies, !cookies.isEmpty else { return }
        for cookie in cookies {
            cookieStore.setCookie(cookie)
        }
        print("[DocumentFlow] synced \(cookies.count) cookie(s) → WKWebView")
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {

        let navigationStore: NestDocumentNavStore
        let onError: () -> Void
        let on404Detected: () -> Void

        private var canGoBackObservation: NSKeyValueObservation?
        private var canGoForwardObservation: NSKeyValueObservation?
        private var loadTimeout: DispatchWorkItem?

        init(
            navigationStore: NestDocumentNavStore,
            onError: @escaping () -> Void,
            on404Detected: @escaping () -> Void
        ) {
            self.navigationStore = navigationStore
            self.onError = onError
            self.on404Detected = on404Detected
        }

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            navigationStore.documentView?.reload()
        }

        func setupNavigationObservers(for documentView: WKWebView, store: NestDocumentNavStore) {
            canGoBackObservation?.invalidate()
            canGoForwardObservation?.invalidate()
            canGoBackObservation = documentView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.navigationStore.updateNavigationState()
                }
            }
            canGoForwardObservation = documentView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.navigationStore.updateNavigationState()
                }
            }
        }

        deinit {
            canGoBackObservation?.invalidate()
            canGoForwardObservation?.invalidate()
            loadTimeout?.cancel()
        }

        func webView(_ view: WKWebView, didFinish navigation: WKNavigation!) {
            loadTimeout?.cancel()
            view.scrollView.refreshControl?.endRefreshing()
            navigationStore.updateNavigationState()
            print("[DocumentFlow] NestDocumentPanel didFinish navigation")

            let js = """
            JSON.stringify({
                viewportFit: document.querySelector('meta[name=viewport]')?.content ?? 'none',
                safeBottom: getComputedStyle(document.documentElement).getPropertyValue('env(safe-area-inset-bottom)'),
                bodyH: document.body.scrollHeight,
                windowH: window.innerHeight,
                devicePixelRatio: window.devicePixelRatio
            })
            """
            view.evaluateJavaScript(js) { result, _ in
//                print("[SafeArea][JS] page info: \(result ?? "nil")")
            }
            let frameJS = "JSON.stringify({x: document.documentElement.getBoundingClientRect().x, y: document.documentElement.getBoundingClientRect().y, w: document.documentElement.getBoundingClientRect().width, h: document.documentElement.getBoundingClientRect().height})"
            view.evaluateJavaScript(frameJS) { result, _ in
//                print("[SafeArea][JS] html frame: \(result ?? "nil")")
            }
            DispatchQueue.main.async {
                let f = view.frame
                let sf = view.scrollView.frame
                let ci = view.scrollView.contentInset
                let ai = view.scrollView.adjustedContentInset
//                print("[SafeArea][WKWebView] view.frame=\(f) scrollView.frame=\(sf)")
//                print("[SafeArea][WKWebView] contentInset=(\(ci.top),\(ci.bottom),\(ci.left),\(ci.right)) adjustedContentInset=(\(ai.top),\(ai.bottom),\(ai.left),\(ai.right))")
            }

            view.evaluateJavaScript("document.title") { [weak self] result, _ in
                if let title = result as? String, title.lowercased().contains("404") {
                    print("[DocumentFlow] NestDocumentPanel 404 detected, title: \(title)")
                    Task { @MainActor in
                        self?.on404Detected()
                    }
                }
            }
        }

        func webView(_ view: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            loadTimeout?.cancel()
            view.scrollView.refreshControl?.endRefreshing()
            print("[DocumentFlow] NestDocumentPanel didFail: \(error.localizedDescription)")
            Task { @MainActor in
                onError()
            }
        }

        func webView(_ view: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            loadTimeout?.cancel()
            let work = DispatchWorkItem { [weak self] in
                print("[DocumentFlow] NestDocumentPanel load timeout (7s)")
                view.scrollView.refreshControl?.endRefreshing()
                Task { @MainActor in
                    self?.onError()
                }
            }
            loadTimeout = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 7, execute: work)
        }
    }
}
