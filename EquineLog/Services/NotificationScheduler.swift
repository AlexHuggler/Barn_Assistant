import BackgroundTasks
import SwiftData

/// Manages BGTaskScheduler registration and background evaluation of high-value moments.
///
/// Background tasks allow overdue health alerts to fire even when the app hasn't been opened in days.
/// The primary evaluation path is foreground (via `NotificationService.evaluateAllMoments`),
/// so background task failures are non-fatal.
enum NotificationScheduler {

    static let backgroundTaskIdentifier = "com.equinelog.notificationEvaluation"

    /// Registers the background app refresh task. Must be called before the end of app launch
    /// (before `application(_:didFinishLaunchingWithOptions:)` returns).
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleBackgroundRefresh(refreshTask)
        }
    }

    /// Submits a request for the next background refresh, with a 4-hour earliest begin date.
    /// Called when the app transitions to background.
    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60) // 4 hours

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Non-fatal: foreground evaluation is the primary path
        }
    }

    private static func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
        // Schedule the next refresh immediately
        scheduleBackgroundRefresh()

        let workTask = Task { @MainActor in
            do {
                let container = try ModelContainerFactory.createProductionContainer()
                let context = container.mainContext
                let descriptor = FetchDescriptor<Horse>()
                let horses = try context.fetch(descriptor)

                NotificationService.shared.evaluateOverdueMomentOnly(horses: horses)

                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            workTask.cancel()
        }
    }
}
