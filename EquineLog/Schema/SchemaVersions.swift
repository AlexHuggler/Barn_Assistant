import Foundation
import SwiftData

// MARK: - Schema Version 1 (Initial Release)

/// Version 1 schema - Initial release of EquineLog
/// Contains: Horse, HealthEvent, FeedSchedule, FeedTemplate
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Horse.self, HealthEvent.self, FeedSchedule.self, FeedTemplate.self]
    }
}

// MARK: - Migration Plan

/// Migration plan for EquineLog data models.
///
/// ## Adding New Migrations
///
/// When making schema changes:
/// 1. Create a new SchemaVX enum conforming to VersionedSchema
/// 2. Define the new models with changes (copy existing models, apply changes)
/// 3. Add a migration stage to `stages` array
/// 4. Test migration with both lightweight and custom migration paths
///
/// ## Example: Adding a new field to Horse
///
/// ```swift
/// enum SchemaV2: VersionedSchema {
///     static var versionIdentifier = Schema.Version(2, 0, 0)
///     static var models: [any PersistentModel.Type] { [HorseV2.self, ...] }
///
///     @Model final class HorseV2 {
///         // ... existing fields ...
///         var breed: String? // New optional field
///     }
/// }
///
/// // Then add migration stage:
/// .migrate(from: SchemaV1.self, to: SchemaV2.self) { context in
///     // Custom migration logic if needed
/// }
/// ```
enum EquineLogMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet - V1 is the initial version
        // Future migrations will be added here as:
        // .migrate(from: SchemaV1.self, to: SchemaV2.self) { context in ... }
        []
    }
}

// MARK: - Model Container Factory

/// Factory for creating the model container with proper migration support.
enum ModelContainerFactory {

    /// Creates a production model container with migration support.
    /// - Returns: Configured ModelContainer for production use
    /// - Throws: ModelContainerError if initialization fails
    static func createProductionContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: EquineLogMigrationPlan.self,
            configurations: [config]
        )
    }

    /// Creates an in-memory container for previews and testing.
    /// - Returns: Configured ModelContainer for testing
    /// - Throws: ModelContainerError if initialization fails
    static func createPreviewContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: EquineLogMigrationPlan.self,
            configurations: [config]
        )
    }
}
