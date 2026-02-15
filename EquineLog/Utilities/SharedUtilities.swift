import Foundation
import UIKit

// MARK: - Feed Slot Resolution

enum FeedSlot: String, CaseIterable, Identifiable {
    case am = "AM"
    case pm = "PM"

    var id: String { rawValue }

    /// The hour boundary where the app switches from AM to PM display.
    /// Before this hour = AM slot; at or after = PM slot.
    static let pmCutoffHour = 14

    /// Returns the currently active feed slot based on the time of day.
    static var current: FeedSlot {
        Calendar.current.component(.hour, from: .now) < pmCutoffHour ? .am : .pm
    }
}

// MARK: - String Utilities

enum StringUtilities {
    /// Parses a comma-separated string into a trimmed, non-empty array.
    static func parseCSV(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Calendar Safe Extensions

extension Calendar {
    /// Safe date addition that returns a fallback instead of crashing.
    func safeDate(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date {
        self.date(byAdding: component, value: value, to: date) ?? date
    }
}

// MARK: - Compliance Thresholds

/// Maximum acceptable average days between visits for each health event type.
/// Beyond this threshold, the cycle is considered non-compliant.
enum CycleThreshold {
    static let farrier = 56      // 8 weeks
    static let vet = 200         // ~6.5 months
    static let deworming = 70    // 10 weeks
    static let dental = 395      // ~13 months

    static func maxDays(for type: HealthEventType) -> Int {
        switch type {
        case .farrier: return farrier
        case .vet: return vet
        case .deworming: return deworming
        case .dental: return dental
        }
    }
}

// MARK: - Haptic Feedback

enum HapticManager {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        default:
            impactMedium.impactOccurred()
        }
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }
}

// MARK: - Form Validation

enum FormValidation {
    struct Result {
        let isValid: Bool
        let message: String?

        static let valid = Result(isValid: true, message: nil)

        static func invalid(_ message: String) -> Result {
            Result(isValid: false, message: message)
        }
    }

    static func validateHorseName(_ name: String) -> Result {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .invalid("Horse name is required.")
        }
        if trimmed.count < 2 {
            return .invalid("Name must be at least 2 characters.")
        }
        if trimmed.count > 40 {
            return .invalid("Name must be under 40 characters.")
        }
        return .valid
    }

    static func validateOwnerName(_ name: String) -> Result {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .invalid("Owner name is required.")
        }
        return .valid
    }

    static func validateCost(_ cost: Double?) -> Result {
        guard let cost else { return .valid } // nil is fine — optional field
        if cost < 0 {
            return .invalid("Cost cannot be negative.")
        }
        if cost > 99_999 {
            return .invalid("Cost seems unusually high. Please verify.")
        }
        return .valid
    }

    static func validateEventDates(eventDate: Date, nextDueDate: Date?) -> Result {
        guard let nextDueDate else { return .valid }
        if nextDueDate < eventDate {
            return .invalid("Next due date must be after the event date.")
        }
        return .valid
    }
}
