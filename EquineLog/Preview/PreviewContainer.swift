import Foundation
import SwiftData

/// Provides an in-memory SwiftData container and sample data for Xcode Previews.
@MainActor
final class PreviewContainer {
    static let shared = PreviewContainer()

    let container: ModelContainer

    init() {
        let schema = Schema([Horse.self, HealthEvent.self, FeedSchedule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        container = try! ModelContainer(for: schema, configurations: [config])

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

        let calendar = Calendar.current

        // Farrier — last visit 6 weeks ago, next due in 2 weeks
        let farrierEvent = HealthEvent(
            type: .farrier,
            date: calendar.date(byAdding: .weekOfYear, value: -6, to: .now)!,
            notes: "Full reset, front shoes. Slight flare on LF corrected.",
            nextDueDate: calendar.date(byAdding: .weekOfYear, value: 2, to: .now),
            cost: 185,
            providerName: "Jim's Farrier Service"
        )

        // Vet — overdue by 2 weeks
        let vetEvent = HealthEvent(
            type: .vet,
            date: calendar.date(byAdding: .month, value: -7, to: .now)!,
            notes: "Spring vaccines, Coggins drawn. All clear.",
            nextDueDate: calendar.date(byAdding: .weekOfYear, value: -2, to: .now),
            cost: 320,
            providerName: "Dr. Patterson, DVM"
        )

        // Deworming — done 3 weeks ago
        let dewormEvent = HealthEvent(
            type: .deworming,
            date: calendar.date(byAdding: .weekOfYear, value: -3, to: .now)!,
            notes: "Quest Plus. FEC was 250 EPG.",
            nextDueDate: calendar.date(byAdding: .weekOfYear, value: 5, to: .now),
            cost: 15
        )

        // Dental — annual, done 8 months ago
        let dentalEvent = HealthEvent(
            type: .dental,
            date: calendar.date(byAdding: .month, value: -8, to: .now)!,
            notes: "Power float. Minor hooks on upper arcades corrected.",
            nextDueDate: calendar.date(byAdding: .month, value: 4, to: .now),
            cost: 250,
            providerName: "Equine Dental Pros"
        )

        // Older farrier event for analytics
        let oldFarrier = HealthEvent(
            type: .farrier,
            date: calendar.date(byAdding: .weekOfYear, value: -14, to: .now)!,
            notes: "Trim and reset.",
            nextDueDate: calendar.date(byAdding: .weekOfYear, value: -6, to: .now),
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
