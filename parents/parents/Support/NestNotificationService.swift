// NestNotificationService.swift
// Local notifications for block reminders

import Foundation
import UserNotifications

/// Schedules and manages local notifications for day blocks.
/// Respects Quiet Hours and Quiet Mode.
final class NestNotificationService {

    static let shared = NestNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let prefix = "nest_block_"

    private init() {}

    // MARK: - Permission

    /// Requests notification permission. Call during onboarding or when enabling reminders.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Returns current authorization status.
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Scheduling

    /// Reschedules notifications for today's blocks. Call when day is saved or loaded.
    func rescheduleForToday(day: DayCradle, settings: NestSettings) {
        cancelAllNestNotifications {
            guard !settings.isQuietModeActive else { return }
            guard NestDateHelper.isToday(day.dateKey) else { return }
            guard let baseDate = NestDateHelper.date(from: day.dateKey) else { return }

            let minutesBefore = Self.minutesBeforeBlock(for: settings.reminderStyle)
            let nowMinutes = NestDateHelper.minutesNow()

            for block in day.blocks where block.reminderEnabled && block.completionMark == .pending {
                let triggerMinutes = block.startFeather - minutesBefore
                guard triggerMinutes > nowMinutes else { continue }

                if Self.isInQuietHours(triggerMinutes: triggerMinutes, settings: settings) {
                    continue
                }

                self.scheduleNotification(
                    block: block,
                    dateKey: day.dateKey,
                    triggerMinutes: triggerMinutes,
                    baseDate: baseDate,
                    minutesBefore: minutesBefore
                )
            }
        }
    }

    /// Cancels all notifications scheduled by this app for blocks.
    func cancelAllNestNotifications(completion: (() -> Void)? = nil) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let ids = requests
                .filter { $0.identifier.hasPrefix(self.prefix) }
                .map(\.identifier)
            if ids.isEmpty {
                DispatchQueue.main.async { completion?() }
                return
            }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
            DispatchQueue.main.async { completion?() }
        }
    }

    // MARK: - Private

    private static func minutesBeforeBlock(for style: ReminderStyle) -> Int {
        switch style {
        case .whisper:   return 5
        case .balanced:  return 10
        case .clockwork: return 15
        }
    }

    private static func isInQuietHours(triggerMinutes: Int, settings: NestSettings) -> Bool {
        let start = settings.quietHoursStart
        let end = settings.quietHoursEnd
        if start > end {
            return triggerMinutes >= start || triggerMinutes < end
        }
        return triggerMinutes >= start && triggerMinutes < end
    }

    private func scheduleNotification(
        block: CradleBlock,
        dateKey: String,
        triggerMinutes: Int,
        baseDate: Date,
        minutesBefore: Int
    ) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = triggerMinutes / 60
        components.minute = triggerMinutes % 60

        guard let triggerDate = calendar.date(from: components),
              triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = block.displayTitle
        content.body = "Starting in \(minutesBefore) min • \(block.timeRangeLabel)"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate), repeats: false)
        let id = "\(prefix)\(block.id.uuidString)_\(dateKey)"

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("🪺 NestNotification schedule error: \(error.localizedDescription)")
            }
        }
    }
}
