import SwiftUI
import SwiftData

@main
struct EquineLogApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainerFactory.createProductionContainer()
        } catch {
            fatalError("""
                EquineLogApp failed to initialize ModelContainer.
                Error: \(error.localizedDescription)

                This is a critical error that prevents the app from launching.
                If this occurs after an app update, the database migration may have failed.

                Debug info:
                - Schema version: \(SchemaV1.versionIdentifier)
                - Error type: \(type(of: error))
                """)
        }

        NotificationScheduler.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                NotificationScheduler.scheduleBackgroundRefresh()
            }
        }
    }
}
