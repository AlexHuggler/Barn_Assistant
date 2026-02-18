import SwiftUI
import SwiftData

@main
struct EquineLogApp: App {
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
