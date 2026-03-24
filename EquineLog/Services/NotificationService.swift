import Foundation
import UserNotifications
import Observation

/// Core notification service that evaluates high-value moments, computes value scores,
/// applies rate limiting, and dispatches local notifications via UNUserNotificationCenter.
///
/// Follows the same @Observable/@MainActor singleton pattern as WeatherService and OnboardingManager.
@Observable
@MainActor
final class NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Properties

    var permissionStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let preferences = NotificationPreferences.shared

    // MARK: - Permission

    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                preferences.notificationsEnabled = true
            }
            await updatePermissionStatus()
        } catch {
            await updatePermissionStatus()
        }
    }

    func updatePermissionStatus() async {
        let settings = await center.notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    // MARK: - Full Evaluation (called on foreground)

    /// Evaluates all high-value moments against the current horse and weather state.
    /// Called when the app returns to the foreground.
    func evaluateAllMoments(horses: [Horse], weatherService: WeatherService) {
        guard preferences.notificationsEnabled else { return }

        evaluateOverdueCascade(horses: horses)
        evaluateUpcomingMaintenance(horses: horses)
        scheduleUnfedAlerts(horses: horses)

        if let temp = weatherService.currentTemperatureF {
            evaluateWeatherMoment(temperature: temp, horses: horses)
        }
    }

    /// Lightweight evaluation for background tasks — only checks overdue events.
    func evaluateOverdueMomentOnly(horses: [Horse]) {
        guard preferences.notificationsEnabled else { return }
        evaluateOverdueCascade(horses: horses)
    }

    // MARK: - Moment 1: Overdue Health Cascade

    private func evaluateOverdueCascade(horses: [Horse]) {
        guard preferences.canSendNotification(for: .overdueCascade) else { return }

        let allOverdue = horses.flatMap { horse in
            horse.overdueEvents.map { (horse: horse, event: $0) }
        }
        guard !allOverdue.isEmpty else { return }

        // Score computation
        var bonuses: [ScoreBonus] = []

        let maxOverdueDays = allOverdue.compactMap { $0.event.daysUntilDue }
            .map { abs($0) }
            .max() ?? 0
        let dayBonus = min(maxOverdueDays * 5, 20)
        if dayBonus > 0 {
            bonuses.append(ScoreBonus(reason: "days overdue", points: dayBonus))
        }

        if allOverdue.contains(where: { $0.event.type == .farrier }) {
            bonuses.append(ScoreBonus(reason: "farrier overdue", points: 10))
        }

        let horsesWithMultiple = Dictionary(grouping: allOverdue, by: \.horse.id)
            .filter { $0.value.count > 1 }
        if !horsesWithMultiple.isEmpty {
            bonuses.append(ScoreBonus(reason: "multiple overdue on same horse", points: 10))
        }

        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        guard score.meetsThreshold else { return }

        // Build notification copy
        let title: String
        let body: String

        if allOverdue.count == 1, let item = allOverdue.first {
            title = "\(item.horse.name)'s \(item.event.type.rawValue.lowercased()) visit is overdue"
            body = "\(item.event.formattedDueStatus). Tap to review and reschedule."
        } else {
            let uniqueHorses = Set(allOverdue.map(\.horse.name))
            let horseList = uniqueHorses.sorted().prefix(2).joined(separator: " and ")
            let suffix = uniqueHorses.count > 2
                ? " and \(uniqueHorses.count - 2) more"
                : ""
            title = "\(allOverdue.count) overdue health items"
            body = "\(horseList)\(suffix) need attention. Delayed care can lead to higher costs."
        }

        scheduleNotification(
            identifier: "overdue-\(Int(Date.now.timeIntervalSince1970))",
            title: title,
            body: body,
            momentType: .overdueCascade
        )
    }

    // MARK: - Moment 2: Cold Snap Blanket Alert

    func evaluateWeatherMoment(temperature: Double, horses: [Horse]) {
        guard preferences.canSendNotification(for: .coldSnapBlanket) else { return }
        guard !horses.isEmpty else { return }

        let lastTemp = preferences.lastNotifiedTemperatureF
        let blanketThresholds = BlanketThresholds.fromUserDefaults()
        let thresholds: [Double] = [blanketThresholds.noBlanket, blanketThresholds.lightSheet, blanketThresholds.mediumWeight, blanketThresholds.heavyWeight]

        // Check if temperature crossed a blanket-recommendation threshold
        let crossedThreshold: Bool
        if let last = lastTemp {
            crossedThreshold = thresholds.contains { threshold in
                (last > threshold && temperature <= threshold) ||
                (last <= threshold && temperature > threshold)
            }
        } else {
            // First reading — store it but don't alert
            preferences.lastNotifiedTemperatureF = temperature
            return
        }

        let significantDrop = lastTemp.map { temperature < $0 - 15 } ?? false

        guard crossedThreshold || significantDrop else {
            preferences.lastNotifiedTemperatureF = temperature
            return
        }

        // Score
        var bonuses: [ScoreBonus] = []
        if crossedThreshold {
            bonuses.append(ScoreBonus(reason: "threshold crossing", points: 20))
        }
        if horses.contains(where: \.isClipped) {
            bonuses.append(ScoreBonus(reason: "clipped horse", points: 10))
        }
        if temperature < blanketThresholds.heavyWeight {
            bonuses.append(ScoreBonus(reason: "extreme cold", points: 10))
        }

        let score = ValueScore(momentType: .coldSnapBlanket, baseScore: 60, bonuses: bonuses)
        guard score.meetsThreshold else {
            preferences.lastNotifiedTemperatureF = temperature
            return
        }

        // Build copy using existing BlanketRecommendation
        let clippedHorses = horses.filter(\.isClipped)
        let hasClipped = !clippedHorses.isEmpty
        let recommendation = BlanketRecommendation.recommend(
            temperatureF: temperature,
            isClipped: hasClipped,
            thresholds: blanketThresholds
        )

        let title = "Temperature at \(Int(temperature))°F — blanket check"
        let body: String
        if let clipped = clippedHorses.first {
            body = "\(clipped.name) (clipped) needs a \(recommendation.rawValue). Check the Weather tab."
        } else {
            body = "Recommendation: \(recommendation.rawValue). \(BlanketRecommendation.description(for: recommendation))"
        }

        scheduleNotification(
            identifier: "weather-\(Int(Date.now.timeIntervalSince1970))",
            title: title,
            body: body,
            momentType: .coldSnapBlanket
        )

        preferences.lastNotifiedTemperatureF = temperature
    }

    // MARK: - Moment 3: Feeding Streak / Unfed Alert

    /// Called after feed toggles to manage streak counter and cancel/schedule unfed alerts.
    func updateFeedingStreak(allHorses: [Horse], allFed: Bool) {
        if allFed {
            // Cancel pending unfed notifications for the current slot
            center.removePendingNotificationRequests(withIdentifiers: ["unfed-am", "unfed-pm"])

            // Increment streak (once per calendar day)
            let today = Calendar.current.startOfDay(for: .now)
            if let lastDate = preferences.lastStreakDate,
               Calendar.current.isDate(lastDate, inSameDayAs: today) {
                return // Already counted today
            }

            preferences.currentFeedingStreak += 1
            preferences.lastStreakDate = today

            // Check for milestone
            let streak = preferences.currentFeedingStreak
            if [7, 14, 30].contains(streak) {
                guard preferences.canSendNotification(for: .feedingStreak) else { return }

                let barnName = OnboardingManager.shared.barnName
                let locationText = barnName.isEmpty ? "your barn" : barnName

                scheduleNotification(
                    identifier: "streak-\(streak)",
                    title: "\(streak)-day feeding streak!",
                    body: "Every horse at \(locationText) has been fed on time for \(streak) days. Excellent care.",
                    momentType: .feedingStreak
                )
            }
        } else {
            // Streak broken
            if preferences.currentFeedingStreak > 0 {
                preferences.currentFeedingStreak = 0
            }
        }
    }

    /// Schedules time-based unfed alerts for AM and PM feeding deadlines.
    /// These fire at the configured deadline hour if horses remain unfed.
    func scheduleUnfedAlerts(horses: [Horse]) {
        guard preferences.canSendNotification(for: .unfedAlert) else { return }

        // Cancel existing and reschedule with current state
        center.removePendingNotificationRequests(withIdentifiers: ["unfed-am", "unfed-pm"])

        scheduleTimeBasedUnfedCheck(
            identifier: "unfed-am",
            hour: preferences.amFeedingDeadlineHour,
            slot: .am,
            horses: horses
        )

        scheduleTimeBasedUnfedCheck(
            identifier: "unfed-pm",
            hour: preferences.pmFeedingDeadlineHour,
            slot: .pm,
            horses: horses
        )
    }

    private func scheduleTimeBasedUnfedCheck(
        identifier: String,
        hour: Int,
        slot: FeedSlot,
        horses: [Horse]
    ) {
        // Pre-compute which horses are unfed in this slot
        let unfedHorses = horses.filter { horse in
            guard let schedule = horse.feedSchedule else { return false }
            return slot == .am ? !schedule.amFedToday : !schedule.pmFedToday
        }
        guard !unfedHorses.isEmpty else { return }

        // Score: higher urgency if medications are due
        var bonuses: [ScoreBonus] = []
        let horseCountBonus = min(unfedHorses.count * 5, 20)
        bonuses.append(ScoreBonus(reason: "unfed horse count", points: horseCountBonus))

        let hasMeds = unfedHorses.contains { horse in
            guard let schedule = horse.feedSchedule else { return false }
            let meds = slot == .am ? schedule.amMedications : schedule.pmMedications
            return !meds.isEmpty
        }
        if hasMeds {
            bonuses.append(ScoreBonus(reason: "medications due", points: 10))
        }

        let score = ValueScore(momentType: .unfedAlert, baseScore: 75, bonuses: bonuses)
        guard score.meetsThreshold else { return }

        // Build copy
        let count = unfedHorses.count
        let title = "\(count) horse\(count == 1 ? "" : "s") still need\(count == 1 ? "s" : "") \(slot.rawValue) feed"
        var body = unfedHorses.prefix(3).map(\.name).joined(separator: ", ")
        if count > 3 {
            body += " and \(count - 3) more"
        }
        body += " haven't been marked as fed."
        if hasMeds {
            body += " Medications are due with this feeding."
        }

        // Schedule at the deadline hour
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = HighValueMomentType.unfedAlert.rawValue

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Moment 4: Upcoming Maintenance Heads-Up

    private func evaluateUpcomingMaintenance(horses: [Horse]) {
        guard preferences.canSendNotification(for: .upcomingMaintenance) else { return }

        let upcomingItems = horses.flatMap { horse in
            horse.upcomingEvents.compactMap { event -> (horse: Horse, event: HealthEvent)? in
                guard let days = event.daysUntilDue, days >= 1, days <= 3 else { return nil }
                return (horse: horse, event: event)
            }
        }

        guard let nearest = upcomingItems.first else { return }
        let (horse, event) = nearest

        // Score
        var bonuses: [ScoreBonus] = []
        if event.daysUntilDue == 1 {
            bonuses.append(ScoreBonus(reason: "due tomorrow", points: 10))
        }
        if event.providerName != nil {
            bonuses.append(ScoreBonus(reason: "provider known", points: 5))
        }
        if event.type == .farrier || event.type == .vet {
            bonuses.append(ScoreBonus(reason: "high-priority type", points: 10))
        }

        let score = ValueScore(momentType: .upcomingMaintenance, baseScore: 65, bonuses: bonuses)
        guard score.meetsThreshold else { return }

        // Build copy
        let days = event.daysUntilDue ?? 3
        let daysText = days == 1 ? "tomorrow" : "in \(days) days"
        let title = "\(event.type.rawValue) visit due \(daysText) for \(horse.name)"
        var body = event.type.defaultCycleDescription + "."
        if let provider = event.providerName {
            body = "\(provider) is scheduled. " + body
        }
        body += " Tap to review."

        scheduleNotification(
            identifier: "upcoming-\(event.id.uuidString)",
            title: title,
            body: body,
            momentType: .upcomingMaintenance
        )
    }

    /// Schedules a calendar-triggered reminder 3 days before a health event's nextDueDate.
    /// Called at event creation time so the notification fires even if the app isn't open.
    func scheduleUpcomingReminder(for event: HealthEvent, horseName: String) {
        guard preferences.notificationsEnabled,
              preferences.upcomingRemindersEnabled,
              let nextDueDate = event.nextDueDate else { return }

        let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: nextDueDate)
        guard let reminderDate, reminderDate > Date.now else { return }

        var triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: reminderDate
        )
        triggerComponents.hour = 9 // Deliver at 9 AM

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "\(event.type.rawValue) due in 3 days for \(horseName)"
        if let provider = event.providerName {
            content.body = "Provider: \(provider). Tap to review details."
        } else {
            content.body = "Time to schedule or confirm the appointment. Tap to review."
        }
        content.sound = .default
        content.categoryIdentifier = HighValueMomentType.upcomingMaintenance.rawValue

        let request = UNNotificationRequest(
            identifier: "reminder-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Core Notification Dispatch

    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        momentType: HighValueMomentType,
        trigger: UNNotificationTrigger? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = momentType.rawValue

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger // nil = deliver immediately
        )

        center.add(request) { [weak self] error in
            if error == nil {
                Task { @MainActor in
                    self?.preferences.recordNotificationSent(for: momentType)
                }
            }
        }
    }

    private init() {}
}
