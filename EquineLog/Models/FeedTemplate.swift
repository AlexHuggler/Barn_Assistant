import Foundation
import SwiftData

@Model
final class FeedTemplate {
    var id: UUID
    var name: String
    var templateDescription: String

    // AM Feed
    var amGrain: String
    var amHay: String
    var amSupplements: [String]
    var amMedications: [String]

    // PM Feed
    var pmGrain: String
    var pmHay: String
    var pmSupplements: [String]
    var pmMedications: [String]

    var specialInstructions: String
    var createdAt: Date
    var usageCount: Int

    // MARK: - Computed Properties

    var summary: String {
        var parts: [String] = []
        if !amGrain.isEmpty { parts.append("AM: \(amGrain)") }
        if !pmGrain.isEmpty { parts.append("PM: \(pmGrain)") }
        return parts.isEmpty ? "No feed details" : parts.joined(separator: ", ")
    }

    init(
        name: String,
        description: String = "",
        amGrain: String = "",
        amHay: String = "",
        amSupplements: [String] = [],
        amMedications: [String] = [],
        pmGrain: String = "",
        pmHay: String = "",
        pmSupplements: [String] = [],
        pmMedications: [String] = [],
        specialInstructions: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.templateDescription = description
        self.amGrain = amGrain
        self.amHay = amHay
        self.amSupplements = amSupplements
        self.amMedications = amMedications
        self.pmGrain = pmGrain
        self.pmHay = pmHay
        self.pmSupplements = pmSupplements
        self.pmMedications = pmMedications
        self.specialInstructions = specialInstructions
        self.createdAt = .now
        self.usageCount = 0
    }

    /// Creates a template from an existing FeedSchedule.
    convenience init(name: String, from schedule: FeedSchedule, description: String = "") {
        self.init(
            name: name,
            description: description,
            amGrain: schedule.amGrain,
            amHay: schedule.amHay,
            amSupplements: schedule.amSupplements,
            amMedications: schedule.amMedications,
            pmGrain: schedule.pmGrain,
            pmHay: schedule.pmHay,
            pmSupplements: schedule.pmSupplements,
            pmMedications: schedule.pmMedications,
            specialInstructions: schedule.specialInstructions
        )
    }

    /// Increments usage count when template is applied.
    func recordUsage() {
        usageCount += 1
    }

    /// Seeds default feed templates into the given model context.
    /// Called once after onboarding completes.
    static func seedDefaults(into context: ModelContext) {
        let defaults: [(name: String, description: String, amGrain: String, amHay: String, pmGrain: String, pmHay: String, instructions: String)] = [
            ("Hay Only",
             "Basic hay diet, no grain",
             "", "2 flakes Timothy",
             "", "2 flakes Timothy",
             ""),
            ("Grain + Hay (Standard)",
             "Common daily ration for an average adult horse",
             "2 qt SafeChoice", "2 flakes Timothy",
             "2 qt SafeChoice", "2 flakes Timothy",
             ""),
            ("Light Work",
             "Reduced grain for easy keepers or light riding",
             "1 qt SafeChoice", "2 flakes Mixed",
             "", "2 flakes Mixed",
             "Monitor weight weekly"),
            ("Performance",
             "Higher calorie diet for horses in heavy work",
             "3 qt Ultium", "3 flakes Orchard/Alfalfa mix",
             "3 qt Ultium", "3 flakes Orchard/Alfalfa mix",
             "Electrolytes in water bucket after exercise"),
            ("Senior",
             "Easily digestible ration for older horses",
             "2 qt Senior feed", "2 flakes soft Timothy",
             "2 qt Senior feed", "2 flakes soft Timothy",
             "Soak grain if needed. Monitor teeth.")
        ]

        for t in defaults {
            let template = FeedTemplate(
                name: t.name,
                description: t.description,
                amGrain: t.amGrain,
                amHay: t.amHay,
                pmGrain: t.pmGrain,
                pmHay: t.pmHay,
                specialInstructions: t.instructions
            )
            context.insert(template)
        }
    }
}
