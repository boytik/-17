// NestAppDelegate.swift
// Little Days: Quiet Mind
// AppDelegate: Firebase Push + Orientation lock

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - 🚀 Nest App Delegate — Firebase + Orientation

final class NestAppDelegate: NSObject,
    UIApplicationDelegate,
    UNUserNotificationCenterDelegate,
    MessagingDelegate {

    static weak var shared: NestAppDelegate?

    /// Orientation lock: portrait for native, portrait+landscape for document view.
    var orientationLock: UIInterfaceOrientationMask = .portrait {
        didSet {
            applyOrientationToWindowScenes()
            notifyOrientationUpdate()
        }
    }

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NestAppDelegate.shared = self
        print("[DocumentFlow] NestAppDelegate didFinishLaunching")

        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        // Запрос разрешения после отображения UI — избегаем чёрного экрана при возврате из диалога
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                print("[DocumentFlow] Notification permission: \(granted ? "granted" : "denied")")
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        orientationLock
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("🪺 Push registration failed: \(error.localizedDescription)")
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("🪺 FCM token: \(token)")
            // TODO: Send token to your server
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    // MARK: - Orientation

    private func applyOrientationToWindowScenes() {
        guard #available(iOS 16.0, *) else { return }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientationLock)
            windowScene.requestGeometryUpdate(prefs) { _ in }
        }
    }

    private func notifyOrientationUpdate() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) else { return }
        var vc: UIViewController? = window.rootViewController
        while let current = vc {
            current.setNeedsUpdateOfSupportedInterfaceOrientations()
            vc = current.presentedViewController
        }
    }
}
