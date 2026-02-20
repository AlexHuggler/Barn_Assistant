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

    // Undo state
    var showUndoBanner = false
    var lastToggledHorse: Horse?
    var lastToggleWasFed: Bool = false
    private var undoTimer: DispatchWorkItem?

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

        // Cancel any pending undo timer
        undoTimer?.cancel()

        if slot == .am {
            schedule.amFedToday.toggle()
            schedule.amFedAt = schedule.amFedToday ? .now : nil
        } else {
            schedule.pmFedToday.toggle()
            schedule.pmFedAt = schedule.pmFedToday ? .now : nil
        }

        // Track for undo
        lastToggledHorse = horse
        lastToggleWasFed = isFed(horse: horse)
        showUndoBanner = true

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

        // Auto-hide undo banner after 4 seconds
        let timer = DispatchWorkItem { [weak self] in
            self?.showUndoBanner = false
            self?.lastToggledHorse = nil
        }
        undoTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timer)
    }

    func undoLastToggle() {
        guard let horse = lastToggledHorse, let schedule = horse.feedSchedule else { return }
        let slot = currentSlot

        // Revert the toggle
        if slot == .am {
            schedule.amFedToday = !lastToggleWasFed
            schedule.amFedAt = schedule.amFedToday ? .now : nil
        } else {
            schedule.pmFedToday = !lastToggleWasFed
            schedule.pmFedAt = schedule.pmFedToday ? .now : nil
        }

        HapticManager.impact(.light)
        undoTimer?.cancel()
        showUndoBanner = false
        lastToggledHorse = nil
        allFedCelebration = false
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

    /// Returns true if there are unfed horses in the current slot.
    func hasUnfedHorses(_ horses: [Horse]) -> Bool {
        horses.contains { !isFed(horse: $0) }
    }

    /// Marks all horses as fed for the current slot.
    func markAllFed(_ horses: [Horse]) {
        let slot = currentSlot
        for horse in horses {
            guard let schedule = horse.feedSchedule else { continue }
            if slot == .am && !schedule.amFedToday {
                schedule.amFedToday = true
                schedule.amFedAt = .now
            } else if slot == .pm && !schedule.pmFedToday {
                schedule.pmFedToday = true
                schedule.pmFedAt = .now
            }
        }
        // Trigger celebration
        allFedCelebration = true
        HapticManager.notification(.success)
    }

    /// Resets all fed status for the current slot (useful for undo).
    func unmarkAllFed(_ horses: [Horse]) {
        let slot = currentSlot
        for horse in horses {
            guard let schedule = horse.feedSchedule else { continue }
            if slot == .am {
                schedule.amFedToday = false
                schedule.amFedAt = nil
            } else {
                schedule.pmFedToday = false
                schedule.pmFedAt = nil
            }
        }
        allFedCelebration = false
        HapticManager.impact(.light)
    }
}
