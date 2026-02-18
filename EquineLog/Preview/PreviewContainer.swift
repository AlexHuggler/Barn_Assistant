import Foundation
import SwiftData

/// Provides an in-memory SwiftData container and sample data for Xcode Previews.
@MainActor
final class PreviewContainer {
    static let shared = PreviewContainer()

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainerFactory.createPreviewContainer()
        } catch {
            // Provide diagnostic information for debugging preview failures
            fatalError("""
                PreviewContainer failed to initialize ModelContainer.
                Error: \(error.localizedDescription)

                This typically indicates a schema configuration issue.
                Check that all @Model classes are correctly defined and
                all relationships have proper inverse definitions.

                Debug info:
                - Schema version: \(SchemaV1.versionIdentifier)
                - Configuration: in-memory only
                """)
        }

        // Insert sample data
        let horse = PreviewContainer.sampleHorse()
        container.mainContext.insert(horse)
    }

    static func sampleHorse() -> Horse {
        let schedule = FeedSchedule(
            amGrain: "2 qt SafeChoice Senior",
            amHay: "2 flakes Timothy",
            amSupplements: ["SmartPak Joint", "Vitamin E"],
            amMedications: ["Gastrogard"],
            pmGrain: "1.5 qt SafeChoice Senior",
            pmHay: "3 flakes Orchard",
            pmSupplements: ["Electrolytes"],
            pmMedications: [],
            specialInstructions: "Soak hay for 30 min. Muzzle on turnout."
        )

        let horse = Horse(
            name: "Whiskey",
            ownerName: "Sarah Mitchell",
            isClipped: true,
            feedSchedule: schedule
        )

        // Farrier — last visit 6 weeks ago, next due in 2 weeks
        let farrierEvent = HealthEvent(
            type: .farrier,
            date: Calendar.safeDate(byAdding: .weekOfYear, value: -6, to: .now),
            notes: "Full reset, front shoes. Slight flare on LF corrected.",
            nextDueDate: Calendar.safeDate(byAdding: .weekOfYear, value: 2, to: .now),
            cost: 185,
            providerName: "Jim's Farrier Service"
        )

        // Vet — overdue by 2 weeks
        let vetEvent = HealthEvent(
            type: .vet,
            date: Calendar.safeDate(byAdding: .month, value: -7, to: .now),
            notes: "Spring vaccines, Coggins drawn. All clear.",
            nextDueDate: Calendar.safeDate(byAdding: .weekOfYear, value: -2, to: .now),
            cost: 320,
            providerName: "Dr. Patterson, DVM"
        )

        // Deworming — done 3 weeks ago
        let dewormEvent = HealthEvent(
            type: .deworming,
            date: Calendar.safeDate(byAdding: .weekOfYear, value: -3, to: .now),
            notes: "Quest Plus. FEC was 250 EPG.",
            nextDueDate: Calendar.safeDate(byAdding: .weekOfYear, value: 5, to: .now),
            cost: 15
        )

        // Dental — annual, done 8 months ago
        let dentalEvent = HealthEvent(
            type: .dental,
            date: Calendar.safeDate(byAdding: .month, value: -8, to: .now),
            notes: "Power float. Minor hooks on upper arcades corrected.",
            nextDueDate: Calendar.safeDate(byAdding: .month, value: 4, to: .now),
            cost: 250,
            providerName: "Equine Dental Pros"
        )

        // Older farrier event for analytics
        let oldFarrier = HealthEvent(
            type: .farrier,
            date: Calendar.safeDate(byAdding: .weekOfYear, value: -14, to: .now),
            notes: "Trim and reset.",
            nextDueDate: Calendar.safeDate(byAdding: .weekOfYear, value: -6, to: .now),
            cost: 175,
            providerName: "Jim's Farrier Service"
        )

        horse.healthEvents = [farrierEvent, vetEvent, dewormEvent, dentalEvent, oldFarrier]

        return horse
    }

    static func sampleHorse2() -> Horse {
        let schedule = FeedSchedule(
            amGrain: "3 qt Strategy",
            amHay: "2 flakes Alfalfa/Timothy mix",
            amSupplements: ["CocoSoya"],
            pmGrain: "3 qt Strategy",
            pmHay: "3 flakes Timothy",
            pmSupplements: ["CocoSoya", "Biotin"],
            specialInstructions: "Easy keeper — monitor weight."
        )

        let horse = Horse(
            name: "Copper",
            ownerName: "James Walker",
            isClipped: false,
            feedSchedule: schedule
        )

        return horse
    }
}
