import Foundation
import SwiftData
import Observation

@Observable
final class FeedBoardViewModel {
    var showingAddHorse = false
    var searchText = ""
    var filterFedStatus: FedFilter = .all

    enum FedFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case needsFeeding = "Needs Feeding"
        case fed = "Fed"

        var id: String { rawValue }
    }

    func filteredHorses(_ horses: [Horse]) -> [Horse] {
        var result = horses

        // Search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.ownerName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Fed status filter
        let isAM = Calendar.current.component(.hour, from: .now) < 14 // Before 2 PM = AM feed

        switch filterFedStatus {
        case .all:
            break
        case .needsFeeding:
            result = result.filter { horse in
                guard let schedule = horse.feedSchedule else { return true }
                return isAM ? !schedule.amFedToday : !schedule.pmFedToday
            }
        case .fed:
            result = result.filter { horse in
                guard let schedule = horse.feedSchedule else { return false }
                return isAM ? schedule.amFedToday : schedule.pmFedToday
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    var currentFeedingSlot: String {
        Calendar.current.component(.hour, from: .now) < 14 ? "AM" : "PM"
    }

    func toggleFed(for horse: Horse) {
        guard let schedule = horse.feedSchedule else { return }
        let isAM = Calendar.current.component(.hour, from: .now) < 14

        if isAM {
            schedule.amFedToday.toggle()
            schedule.amFedAt = schedule.amFedToday ? .now : nil
        } else {
            schedule.pmFedToday.toggle()
            schedule.pmFedAt = schedule.pmFedToday ? .now : nil
        }
    }

    func isFed(horse: Horse) -> Bool {
        guard let schedule = horse.feedSchedule else { return false }
        let isAM = Calendar.current.component(.hour, from: .now) < 14
        return isAM ? schedule.amFedToday : schedule.pmFedToday
    }
}
