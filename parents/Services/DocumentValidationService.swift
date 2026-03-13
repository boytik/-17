// DocumentValidationService.swift
// Little Days: Quiet Mind
// First launch choice, URL management, validations

import Foundation
import Network
import UIKit

// MARK: - 🌐 Document Validation Service

enum DocumentValidationService {

    private static let firstLaunchChoiceKey = "firstLaunchChoice"
    private static let savedDestinationKey = "nest_document_saved_destination"
    /// Primary/fallback destination. Change for your server. Avoid Instagram — it blocks WKWebView.
    private static let primaryDestinationString = "https://www.google.com/"

    // MARK: - First Launch Choice

    static func getFirstLaunchChoice() -> String? {
        UserDefaults.standard.string(forKey: firstLaunchChoiceKey)
    }

    static func setFirstLaunchChoice(_ choice: String) {
        UserDefaults.standard.set(choice, forKey: firstLaunchChoiceKey)
    }

    // MARK: - Destination (URL)

    /// Returns saved destination or fallback.
    static func getSavedDestination() -> URL? {
        if let saved = UserDefaults.standard.string(forKey: savedDestinationKey) {
            if saved.lowercased().contains("instagram") {
                print("[DocumentFlow] cleared instagram from saved destination")
                UserDefaults.standard.removeObject(forKey: savedDestinationKey)
            } else if let destination = URL(string: saved) {
                print("[DocumentFlow] getSavedDestination: \(saved)")
                return destination
            }
        }
        print("[DocumentFlow] getSavedDestination: fallback \(primaryDestinationString)")
        return URL(string: primaryDestinationString)
    }

    static func saveDestination(_ destination: URL) {
        UserDefaults.standard.set(destination.absoluteString, forKey: savedDestinationKey)
    }

    static var primaryDestination: URL {
        URL(string: primaryDestinationString)!
    }

    static var fallbackDestination: URL {
        URL(string: primaryDestinationString)!
    }

    // MARK: - Validations (First Launch)

    static func checkInternet(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        var didComplete = false
        let queue = DispatchQueue(label: "DocumentValidation")
        monitor.pathUpdateHandler = { path in
            guard !didComplete else { return }
            didComplete = true
            monitor.cancel()
            let ok = path.status == .satisfied
            print("[DocumentFlow] checkInternet (pathUpdate): \(ok ? "OK" : "no connection")")
            DispatchQueue.main.async { completion(ok) }
        }
        monitor.start(queue: queue)
        queue.asyncAfter(deadline: .now() + 0.3) {
            guard !didComplete else { return }
            let status = monitor.currentPath.status
            if status == .satisfied || status == .unsatisfied {
                didComplete = true
                monitor.cancel()
                let ok = status == .satisfied
                print("[DocumentFlow] checkInternet (0.3s check): \(ok ? "OK" : "no connection")")
                DispatchQueue.main.async { completion(ok) }
            }
        }
        queue.asyncAfter(deadline: .now() + 2) {
            guard !didComplete else { return }
            didComplete = true
            monitor.cancel()
            print("[DocumentFlow] checkInternet (timeout 2s): no connection")
            DispatchQueue.main.async { completion(false) }
        }
    }

    static func isIPad() -> Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Simplified validation: internet + device. Returns (success, destination).
    static func runFirstLaunchValidations(completion: @escaping (Bool, URL?) -> Void) {
        if isIPad() {
            print("[DocumentFlow] validation: iPad → nativeApp")
            setFirstLaunchChoice("nativeApp")
            completion(false, nil)
            return
        }

        print("[DocumentFlow] validation: checking internet...")
        checkInternet { hasInternet in
            if !hasInternet {
                print("[DocumentFlow] validation: no internet → nativeApp")
                setFirstLaunchChoice("nativeApp")
                completion(false, nil)
                return
            }

            let destination = primaryDestination
            print("[DocumentFlow] validation: internet OK, saving \(destination.absoluteString)")
            saveDestination(destination)
            setFirstLaunchChoice("webView")
            completion(true, destination)
        }
    }
}
