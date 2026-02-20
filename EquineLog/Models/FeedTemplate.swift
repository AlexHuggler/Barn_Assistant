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
}
