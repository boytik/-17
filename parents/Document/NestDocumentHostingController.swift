// NestDocumentHostingController.swift
// Little Days: Quiet Mind
// UIViewController hosting document view + orientation lock for landscape

import SwiftUI
import UIKit

// MARK: - 🌐 Nest Document Hosting Controller

final class NestDocumentHostingController: UIViewController {

    let navStore = NestDocumentNavStore()
    var hostingController: UIHostingController<NestDocumentContainer>?
    var currentDestination: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)
        print("[DocumentFlow] NestDocumentHostingController viewDidLoad")
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let i = view.safeAreaInsets
//        print("[SafeArea][UIKit] viewSafeAreaInsetsDidChange: top=\(i.top) bottom=\(i.bottom) left=\(i.left) right=\(i.right)")
        neutralizeSafeArea()
    }

    /// The root SwiftUI UIHostingController (WindowGroup) propagates safe area insets
    /// down the entire VC hierarchy. We cancel bottom/left/right on self so neither
    /// this VC nor its child hosting controller receive those insets.
    /// Top is kept as-is — it carries the notch/status bar inset we want to preserve.
    private func neutralizeSafeArea() {
        let insets = view.safeAreaInsets
        // additionalSafeAreaInsets are additive, so to zero out what the parent pushed in
        // we set negative values equal to the current insets (minus top which we keep).
        additionalSafeAreaInsets = UIEdgeInsets(
            top: -insets.top,
            left: -insets.left,
            bottom: -insets.bottom,
            right: -insets.right
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setDocumentOrientation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setDocumentOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NestAppDelegate.shared?.orientationLock = .portrait
    }

    func updateContent(
        destination: URL,
        onError: @escaping () -> Void,
        on404Detected: @escaping () -> Void
    ) {
        currentDestination = destination
        print("[DocumentFlow] updateContent: loading \(destination.absoluteString)")

        let content = NestDocumentContainer(
            destination: destination,
            navStore: navStore,
            onError: onError,
            on404Detected: on404Detected
        )

        if let hosting = hostingController {
            hosting.rootView = content
        } else {
            let hosting = UIHostingController(rootView: content)
            hostingController = hosting
            addChild(hosting)
            view.addSubview(hosting.view)
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
                hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            hosting.didMove(toParent: self)
            neutralizeSafeArea()
        }
    }

    private func setDocumentOrientation() {
        guard let appDelegate = NestAppDelegate.shared else { return }
        let mask: UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
        appDelegate.orientationLock = mask
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appDelegate.orientationLock = mask
        }
    }
}
