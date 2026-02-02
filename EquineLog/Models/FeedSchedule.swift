import Foundation
import SwiftData

@Model
final class FeedSchedule {
    var id: UUID

    // AM Feed
    var amGrain: String
    var amHay: String
    var amSupplements: [String]
    var amMedications: [String]
    var amFedAt: Date?
    var amFedToday: Bool

    // PM Feed
    var pmGrain: String
    var pmHay: String
    var pmSupplements: [String]
    var pmMedications: [String]
    var pmFedAt: Date?
    var pmFedToday: Bool

    var specialInstructions: String

    var horse: Horse?

    // MARK: - Computed Properties

    var amSummary: String {
        var parts: [String] = []
        if !amGrain.isEmpty { parts.append(amGrain) }
        if !amHay.isEmpty { parts.append(amHay) }
        return parts.isEmpty ? "No AM feed set" : parts.joined(separator: " + ")
    }

    var pmSummary: String {
        var parts: [String] = []
        if !pmGrain.isEmpty { parts.append(pmGrain) }
        if !pmHay.isEmpty { parts.append(pmHay) }
        return parts.isEmpty ? "No PM feed set" : parts.joined(separator: " + ")
    }

    var allSupplements: [String] {
        Array(Set(amSupplements + pmSupplements)).sorted()
    }

    var allMedications: [String] {
        Array(Set(amMedications + pmMedications)).sorted()
    }

    init(
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
        self.amGrain = amGrain
        self.amHay = amHay
        self.amSupplements = amSupplements
        self.amMedications = amMedications
        self.amFedAt = nil
        self.amFedToday = false
        self.pmGrain = pmGrain
        self.pmHay = pmHay
        self.pmSupplements = pmSupplements
        self.pmMedications = pmMedications
        self.pmFedAt = nil
        self.pmFedToday = false
        self.specialInstructions = specialInstructions
    }

    /// Resets daily feeding status. Call at the start of each new day.
    func resetDailyStatus() {
        amFedToday = false
        amFedAt = nil
        pmFedToday = false
        pmFedAt = nil
    }
}
