// NestDocumentContainer.swift
// Little Days: Quiet Mind
// Document view + NavBar in one stack, orientation-aware (panel opposite notch)

import SwiftUI

// MARK: - 🌐 Nest Document Container — Orientation-Aware Layout

struct NestDocumentContainer: View {

    let destination: URL
    @ObservedObject var navStore: NestDocumentNavStore
    let onError: () -> Void
    let on404Detected: () -> Void

    @State private var orientation: UIDeviceOrientation = .portrait

    private var homeDestination: URL? { DocumentValidationService().getSavedURL() }

    var body: some View {
        NestDocumentContainerContent(
            destination: destination,
            navStore: navStore,
            homeDestination: homeDestination,
            onError: onError,
            on404Detected: on404Detected,
            orientation: orientation
        )
        .background(NestPalette.safeAreaNest)
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
    }
}

// MARK: - Window helpers

/// Safe area insets from the key window — reliable even inside ignoresSafeArea.
private func windowSafeAreaInsets() -> UIEdgeInsets {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?
        .safeAreaInsets ?? .zero
}

/// Interface orientation of the key window scene.
private func windowInterfaceOrientation() -> UIInterfaceOrientation {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?
        .interfaceOrientation ?? .portrait
}

// MARK: - Content

private struct NestDocumentContainerContent: View {

    let destination: URL
    @ObservedObject var navStore: NestDocumentNavStore
    let homeDestination: URL?
    let onError: () -> Void
    let on404Detected: () -> Void
    var orientation: UIDeviceOrientation

    @State private var safeInsets: UIEdgeInsets = windowSafeAreaInsets()
    @State private var interfaceOrientation: UIInterfaceOrientation = windowInterfaceOrientation()

    var body: some View {
        let isLandscape = interfaceOrientation.isLandscape
        // Notch side determined by interface orientation.
        // landscapeRight (iface=4): notch on LEFT side of screen
        // landscapeLeft (iface=3): notch on RIGHT side of screen
        let notchOnLeft  = interfaceOrientation == .landscapeRight
        let notchOnRight = interfaceOrientation == .landscapeLeft

        let safeTop      = safeInsets.top
        let safeLeft     = safeInsets.left
        let safeRight    = safeInsets.right

        let _ = print("[SafeArea] iface=\(interfaceOrientation.rawValue) isLandscape=\(isLandscape) notchLeft=\(notchOnLeft) notchRight=\(notchOnRight) | top=\(safeTop) left=\(safeLeft) right=\(safeRight) bottom=\(safeInsets.bottom)")

        let documentPanel = NestDocumentPanel(
            destination: destination,
            navigationStore: navStore,
            onError: onError,
            on404Detected: on404Detected
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        let navBarView = NestDocumentNavBar(
            navStore: navStore,
            homeDestination: homeDestination,
            isVertical: isLandscape
        )

        Group {
            if isLandscape {
                if notchOnLeft {
                    // Notch on LEFT → navBar on RIGHT
                    // Notch inset (safeLeft) applied to documentPanel leading edge
                    HStack(spacing: 0) {
                        documentPanel
                            .padding(.leading, safeLeft)
                            .layoutPriority(1)
                        navBarView
                            .frame(maxHeight: .infinity, alignment: .center)
                            .background(NestTabBarBackground())
                    }
                } else {
                    // Notch on RIGHT → navBar on LEFT
                    // Notch inset (safeRight) applied to documentPanel trailing edge
                    HStack(spacing: 0) {
                        navBarView
                            .frame(maxHeight: .infinity, alignment: .center)
                            .background(NestTabBarBackground())
                        documentPanel
                            .padding(.trailing, safeRight)
                            .layoutPriority(1)
                    }
                }
            } else {
                // Portrait — navBar at bottom, top padding for notch
                VStack(spacing: 0) {
                    documentPanel.layoutPriority(1)
                    navBarView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(NestTabBarBackground())
                }
                .padding(.top, safeTop)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                safeInsets = windowSafeAreaInsets()
                interfaceOrientation = windowInterfaceOrientation()
//                print("[SafeArea] refreshed: iface=\(interfaceOrientation.rawValue) top=\(safeInsets.top) left=\(safeInsets.left) right=\(safeInsets.right)")
            }
        }
    }
}
