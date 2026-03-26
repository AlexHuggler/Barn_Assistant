import Foundation
import Observation

/// UserDefaults-backed notification preferences following the OnboardingManager singleton pattern.
///
/// Controls per-moment toggles, feeding deadline hours, streak tracking, and rate limiting state.
/// All properties persist across app launches via UserDefaults.
@Observable
@MainActor
final class NotificationPreferences {

    // MARK: - Singleton

    static let shared = NotificationPreferences()

    // MARK: - Constants

    static let maxNotificationsPerDay = 4

    // MARK: - Keys

    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let overdueAlertsEnabled = "overdueAlertsEnabled"
        static let weatherAlertsEnabled = "weatherAlertsEnabled"
        static let feedingAlertsEnabled = "feedingAlertsEnabled"
        static let upcomingRemindersEnabled = "upcomingRemindersEnabled"
        static let amFeedingDeadlineHour = "amFeedingDeadlineHour"
        static let pmFeedingDeadlineHour = "pmFeedingDeadlineHour"
        static let currentFeedingStreak = "currentFeedingStreak"
        static let lastStreakDate = "lastStreakDate"
        static let lastNotifiedDates = "lastNotifiedDates"
        static let dailyNotificationCount = "dailyNotificationCount"
        static let dailyCountResetDate = "dailyCountResetDate"
        static let lastNotifiedTemperatureF = "lastNotifiedTemperatureF"
    }

    // MARK: - Master Toggle

    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notificationsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    // MARK: - Per-Moment Toggles

    var overdueAlertsEnabled: Bool {
        get {
            // Default true: register default so first-time reads return true
            UserDefaults.standard.object(forKey: Keys.overdueAlertsEnabled) as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.overdueAlertsEnabled) }
    }

    var weatherAlertsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.weatherAlertsEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.weatherAlertsEnabled) }
    }

    var feedingAlertsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.feedingAlertsEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.feedingAlertsEnabled) }
    }

    var upcomingRemindersEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.upcomingRemindersEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.upcomingRemindersEnabled) }
    }

    // MARK: - Feeding Deadline Hours

    var amFeedingDeadlineHour: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: Keys.amFeedingDeadlineHour)
            return stored == 0 ? 11 : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.amFeedingDeadlineHour) }
    }

    var pmFeedingDeadlineHour: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: Keys.pmFeedingDeadlineHour)
            return stored == 0 ? 18 : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.pmFeedingDeadlineHour) }
    }

    // MARK: - Streak Tracking

    var currentFeedingStreak: Int {
        get { UserDefaults.standard.integer(forKey: Keys.currentFeedingStreak) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.currentFeedingStreak) }
    }

    var lastStreakDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastStreakDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastStreakDate) }
    }

    // MARK: - Rate Limiting State

    var dailyNotificationCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.dailyNotificationCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dailyNotificationCount) }
    }

    var dailyCountResetDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.dailyCountResetDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dailyCountResetDate) }
    }

    var lastNotifiedTemperatureF: Double? {
        get {
            UserDefaults.standard.object(forKey: Keys.lastNotifiedTemperatureF) as? Double
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: Keys.lastNotifiedTemperatureF)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastNotifiedTemperatureF)
            }
        }
    }

    // MARK: - Last Notified Dates (per moment type)

    /// Returns the last time a notification of the given type was sent.
    func lastNotifiedDate(for type: HighValueMomentType) -> Date? {
        let dict = loadLastNotifiedDates()
        guard let interval = dict[type.rawValue] else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    /// Records that a notification of the given type was sent now.
    func recordLastNotified(for type: HighValueMomentType) {
        var dict = loadLastNotifiedDates()
        dict[type.rawValue] = Date.now.timeIntervalSince1970
        saveLastNotifiedDates(dict)
    }

    private func loadLastNotifiedDates() -> [String: TimeInterval] {
        guard let data = UserDefaults.standard.data(forKey: Keys.lastNotifiedDates) else { return [:] }
        do {
            return try JSONDecoder().decode([String: TimeInterval].self, from: data)
        } catch {
            #if DEBUG
            print("[NotificationPreferences] Failed to decode lastNotifiedDates: \(error)")
            #endif
            return [:]
        }
    }

    private func saveLastNotifiedDates(_ dict: [String: TimeInterval]) {
        do {
            let data = try JSONEncoder().encode(dict)
            UserDefaults.standard.set(data, forKey: Keys.lastNotifiedDates)
        } catch {
            #if DEBUG
            print("[NotificationPreferences] Failed to encode lastNotifiedDates: \(error)")
            #endif
        }
    }

    // MARK: - Rate Limiting Helpers

    /// Returns true if a notification of this type is allowed right now.
    /// Checks: master toggle, per-moment toggle, daily cap, and per-moment cooldown.
    func canSendNotification(for type: HighValueMomentType) -> Bool {
        guard notificationsEnabled else { return false }
        guard isEnabled(for: type) else { return false }
        guard isDailyCapAvailable() else { return false }
        guard isCooldownElapsed(for: type) else { return false }
        return true
    }

    /// Records that a notification was sent: updates the daily counter and per-moment timestamp.
    func recordNotificationSent(for type: HighValueMomentType) {
        resetDailyCountIfNeeded()
        dailyNotificationCount += 1
        recordLastNotified(for: type)
    }

    // MARK: - Private Helpers

    private func isEnabled(for type: HighValueMomentType) -> Bool {
        switch type {
        case .overdueCascade: return overdueAlertsEnabled
        case .coldSnapBlanket: return weatherAlertsEnabled
        case .feedingStreak, .unfedAlert: return feedingAlertsEnabled
        case .upcomingMaintenance: return upcomingRemindersEnabled
        }
    }

    private func isDailyCapAvailable() -> Bool {
        resetDailyCountIfNeeded()
        return dailyNotificationCount < Self.maxNotificationsPerDay
    }

    private func isCooldownElapsed(for type: HighValueMomentType) -> Bool {
        guard let lastFired = lastNotifiedDate(for: type) else { return true }
        return Date.now.timeIntervalSince(lastFired) >= type.cooldownInterval
    }

    private func resetDailyCountIfNeeded() {
        guard let resetDate = dailyCountResetDate else {
            dailyCountResetDate = Date.now
            dailyNotificationCount = 0
            return
        }
        if !Calendar.current.isDateInToday(resetDate) {
            dailyNotificationCount = 0
            dailyCountResetDate = Date.now
        }
    }

    private init() {}
}
