import Foundation
import SwiftData
import Observation

@Observable
final class HealthTimelineViewModel {
    var selectedFilter: HealthEventType?
    var showingAddEvent = false
    var selectedHorse: Horse?

    func upcomingEvents(from horses: [Horse]) -> [HealthEventGroup] {
        let allEvents = horses.flatMap { horse in
            horse.healthEvents.compactMap { event -> HealthEventItem? in
                guard event.nextDueDate != nil else { return nil }
                return HealthEventItem(event: event, horseName: horse.name)
            }
        }
        .sorted { ($0.event.nextDueDate ?? .distantFuture) < ($1.event.nextDueDate ?? .distantFuture) }

        let filtered: [HealthEventItem]
        if let filter = selectedFilter {
            filtered = allEvents.filter { $0.event.type == filter }
        } else {
            filtered = allEvents
        }

        // Group by status: Overdue, This Week, This Month, Later
        let calendar = Calendar.current
        let weekFromNow = calendar.safeDate(byAdding: .weekOfYear, value: 1, to: .now)
        let monthFromNow = calendar.safeDate(byAdding: .month, value: 1, to: .now)

        let overdue = filtered.filter { $0.event.isOverdue }
        let thisWeek = filtered.filter { item in
            guard let due = item.event.nextDueDate, !item.event.isOverdue else { return false }
            return due <= weekFromNow
        }
        let thisMonth = filtered.filter { item in
            guard let due = item.event.nextDueDate, !item.event.isOverdue else { return false }
            return due > weekFromNow && due <= monthFromNow
        }
        let later = filtered.filter { item in
            guard let due = item.event.nextDueDate, !item.event.isOverdue else { return false }
            return due > monthFromNow
        }

        var groups: [HealthEventGroup] = []
        if !overdue.isEmpty { groups.append(HealthEventGroup(title: "Overdue", items: overdue, isOverdue: true)) }
        if !thisWeek.isEmpty { groups.append(HealthEventGroup(title: "This Week", items: thisWeek)) }
        if !thisMonth.isEmpty { groups.append(HealthEventGroup(title: "This Month", items: thisMonth)) }
        if !later.isEmpty { groups.append(HealthEventGroup(title: "Upcoming", items: later)) }

        return groups
    }
}

// MARK: - Supporting Types

struct HealthEventItem: Identifiable {
    let event: HealthEvent
    let horseName: String
    var id: UUID { event.id }
}

struct HealthEventGroup: Identifiable {
    let title: String
    let items: [HealthEventItem]
    var isOverdue: Bool = false
    var id: String { title }
}
