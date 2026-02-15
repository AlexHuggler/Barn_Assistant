import Foundation
import SwiftData
import Observation

@Observable
final class FeedBoardViewModel {
    var showingAddHorse = false
    var searchText = ""
    var filterFedStatus: FedFilter = .all
    var horseToDelete: Horse?
    var showingDeleteConfirmation = false
    var showingQuickLog = false
    var quickLogHorse: Horse?
    var allFedCelebration = false

    enum FedFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case needsFeeding = "Needs Feeding"
        case fed = "Fed"

        var id: String { rawValue }
    }

    var currentSlot: FeedSlot { FeedSlot.current }

    func filteredHorses(_ horses: [Horse]) -> [Horse] {
        var result = horses

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.ownerName.localizedCaseInsensitiveContains(searchText)
            }
        }

        let slot = currentSlot
        switch filterFedStatus {
        case .all:
            break
        case .needsFeeding:
            result = result.filter { horse in
                guard let schedule = horse.feedSchedule else { return true }
                return slot == .am ? !schedule.amFedToday : !schedule.pmFedToday
            }
        case .fed:
            result = result.filter { horse in
                guard let schedule = horse.feedSchedule else { return false }
                return slot == .am ? schedule.amFedToday : schedule.pmFedToday
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    func toggleFed(for horse: Horse, allHorses: [Horse]) {
        guard let schedule = horse.feedSchedule else { return }
        let slot = currentSlot

        if slot == .am {
            schedule.amFedToday.toggle()
            schedule.amFedAt = schedule.amFedToday ? .now : nil
        } else {
            schedule.pmFedToday.toggle()
            schedule.pmFedAt = schedule.pmFedToday ? .now : nil
        }

        // Haptic on toggle
        if isFed(horse: horse) {
            HapticManager.impact(.medium)
        } else {
            HapticManager.impact(.light)
        }

        // Check if all horses are now fed — trigger celebration
        let allFed = allHorses.allSatisfy { isFed(horse: $0) }
        if allFed && !allHorses.isEmpty {
            allFedCelebration = true
            HapticManager.notification(.success)
        }
    }

    func isFed(horse: Horse) -> Bool {
        guard let schedule = horse.feedSchedule else { return false }
        return currentSlot == .am ? schedule.amFedToday : schedule.pmFedToday
    }

    func fedCount(from horses: [Horse]) -> Int {
        horses.filter { isFed(horse: $0) }.count
    }

    /// Checks if feed status was set on a previous day and resets if needed.
    func autoResetIfNewDay(horses: [Horse]) {
        let calendar = Calendar.current
        for horse in horses {
            guard let schedule = horse.feedSchedule else { continue }

            if let amDate = schedule.amFedAt, !calendar.isDateInToday(amDate) {
                schedule.resetDailyStatus()
            } else if let pmDate = schedule.pmFedAt, !calendar.isDateInToday(pmDate) {
                schedule.resetDailyStatus()
            }
        }
    }

    func confirmDelete(horse: Horse) {
        horseToDelete = horse
        showingDeleteConfirmation = true
    }

    func requestQuickLog(horse: Horse) {
        quickLogHorse = horse
        showingQuickLog = true
    }
}
