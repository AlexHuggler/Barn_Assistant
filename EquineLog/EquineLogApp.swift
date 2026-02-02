import SwiftUI
import SwiftData

@main
struct EquineLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Horse.self, HealthEvent.self, FeedSchedule.self])
    }
}
