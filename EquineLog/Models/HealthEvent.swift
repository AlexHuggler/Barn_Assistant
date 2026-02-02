import Foundation
import SwiftData

@Model
final class HealthEvent {
    var id: UUID
    var type: HealthEventType
    var date: Date
    var notes: String
    var nextDueDate: Date?
    var cost: Double?
    var providerName: String?

    var horse: Horse?

    // MARK: - Computed Properties

    var isOverdue: Bool {
        guard let nextDueDate else { return false }
        return nextDueDate < Date.now
    }

    var daysUntilDue: Int? {
        guard let nextDueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: nextDueDate).day
    }

    var formattedDueStatus: String {
        guard let days = daysUntilDue else { return "No date set" }
        if days < 0 {
            return "Overdue by \(abs(days)) day\(abs(days) == 1 ? "" : "s")"
        } else if days == 0 {
            return "Due today"
        } else {
            return "Due in \(days) day\(days == 1 ? "" : "s")"
        }
    }

    init(
        type: HealthEventType,
        date: Date,
        notes: String = "",
        nextDueDate: Date? = nil,
        cost: Double? = nil,
        providerName: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.date = date
        self.notes = notes
        self.nextDueDate = nextDueDate
        self.cost = cost
        self.providerName = providerName
    }

    /// Generates the next due date based on standard cycles.
    static func suggestedNextDueDate(for type: HealthEventType, from date: Date) -> Date? {
        let calendar = Calendar.current
        switch type {
        case .farrier:
            return calendar.date(byAdding: .weekOfYear, value: 7, to: date) // ~7 weeks
        case .vet:
            return calendar.date(byAdding: .month, value: 6, to: date) // biannual
        case .deworming:
            return calendar.date(byAdding: .month, value: 2, to: date) // 8-week cycle
        case .dental:
            return calendar.date(byAdding: .year, value: 1, to: date) // annual
        }
    }
}

// MARK: - HealthEventType

enum HealthEventType: String, Codable, CaseIterable, Identifiable {
    case farrier = "Farrier"
    case vet = "Vet"
    case deworming = "Deworming"
    case dental = "Dental"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .farrier: return "hammer.fill"
        case .vet: return "cross.case.fill"
        case .deworming: return "pills.fill"
        case .dental: return "mouth.fill"
        }
    }

    var defaultCycleDescription: String {
        switch self {
        case .farrier: return "Every 6-8 weeks"
        case .vet: return "Biannual checkup"
        case .deworming: return "Every 8 weeks"
        case .dental: return "Annual float"
        }
    }
}
