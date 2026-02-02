import Foundation
import SwiftData

@Model
final class Horse {
    var id: UUID
    var name: String
    var ownerName: String
    @Attribute(.externalStorage) var imageData: Data?
    var isClipped: Bool
    var dateAdded: Date

    @Relationship(deleteRule: .cascade, inverse: \HealthEvent.horse)
    var healthEvents: [HealthEvent]

    @Relationship(deleteRule: .cascade, inverse: \FeedSchedule.horse)
    var feedSchedule: FeedSchedule?

    // MARK: - Computed Properties

    var upcomingEvents: [HealthEvent] {
        healthEvents
            .filter { $0.nextDueDate != nil }
            .sorted { ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture) }
    }

    var overdueEvents: [HealthEvent] {
        healthEvents.filter { event in
            guard let dueDate = event.nextDueDate else { return false }
            return dueDate < Date.now
        }
    }

    var recentEvents: [HealthEvent] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return healthEvents
            .filter { $0.date >= thirtyDaysAgo }
            .sorted { $0.date > $1.date }
    }

    init(
        name: String,
        ownerName: String,
        imageData: Data? = nil,
        isClipped: Bool = false,
        healthEvents: [HealthEvent] = [],
        feedSchedule: FeedSchedule? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.ownerName = ownerName
        self.imageData = imageData
        self.isClipped = isClipped
        self.dateAdded = .now
        self.healthEvents = healthEvents
        self.feedSchedule = feedSchedule
    }
}
