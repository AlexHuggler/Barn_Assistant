import Foundation

// MARK: - Moment Types

enum HighValueMomentType: String, CaseIterable, Identifiable {
    case overdueCascade = "overdueCascade"
    case coldSnapBlanket = "coldSnapBlanket"
    case feedingStreak = "feedingStreak"
    case unfedAlert = "unfedAlert"
    case upcomingMaintenance = "upcomingMaintenance"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .overdueCascade: return "Overdue Health Alerts"
        case .coldSnapBlanket: return "Weather & Blanket Alerts"
        case .feedingStreak: return "Feeding Streaks"
        case .unfedAlert: return "Unfed Reminders"
        case .upcomingMaintenance: return "Upcoming Maintenance"
        }
    }

    var description: String {
        switch self {
        case .overdueCascade: return "Alert when health events are past due"
        case .coldSnapBlanket: return "Notify when temperature changes affect blanketing"
        case .feedingStreak: return "Celebrate consistent feeding milestones"
        case .unfedAlert: return "Remind when horses haven't been fed near slot deadlines"
        case .upcomingMaintenance: return "Heads-up 3 days before scheduled appointments"
        }
    }

    var iconName: String {
        switch self {
        case .overdueCascade: return "exclamationmark.triangle.fill"
        case .coldSnapBlanket: return "thermometer.snowflake"
        case .feedingStreak: return "flame.fill"
        case .unfedAlert: return "bell.badge.fill"
        case .upcomingMaintenance: return "calendar.badge.clock"
        }
    }

    /// Minimum value score required for this moment type to trigger a notification.
    var threshold: Int {
        switch self {
        case .overdueCascade: return 80
        case .coldSnapBlanket: return 70
        case .feedingStreak: return 50
        case .unfedAlert: return 70
        case .upcomingMaintenance: return 65
        }
    }

    /// Minimum time between consecutive notifications of this type.
    var cooldownInterval: TimeInterval {
        switch self {
        case .overdueCascade: return 24 * 60 * 60      // 24 hours
        case .coldSnapBlanket: return 12 * 60 * 60     // 12 hours
        case .feedingStreak: return 24 * 60 * 60       // 24 hours
        case .unfedAlert: return 4 * 60 * 60           // 4 hours (AM and PM are separate windows)
        case .upcomingMaintenance: return 24 * 60 * 60 // 24 hours
        }
    }
}

// MARK: - Value Scoring

struct ScoreBonus {
    let reason: String
    let points: Int
}

struct ValueScore {
    let momentType: HighValueMomentType
    let baseScore: Int
    let bonuses: [ScoreBonus]

    /// Capped at 120 to prevent any single moment from dominating.
    var totalScore: Int {
        min(baseScore + bonuses.reduce(0) { $0 + $1.points }, 120)
    }

    var meetsThreshold: Bool {
        totalScore >= momentType.threshold
    }
}
