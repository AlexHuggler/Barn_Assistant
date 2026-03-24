import Testing
import SwiftData
import Foundation
@testable import EquineLog

/// Tests for FeedBoardViewModel filtering, fed status, and batch operations.
@Suite("Feed Board ViewModel Tests")
@MainActor
struct FeedBoardViewModelTests {

    // MARK: - Helpers

    /// Creates an in-memory container with test horses and returns (viewModel, horses, container).
    private static func makeTestSetup(
        horses: [(name: String, owner: String)] = [
            ("Alpha", "Owner A"),
            ("Bravo", "Owner B"),
            ("Charlie", "Owner C")
        ]
    ) throws -> (FeedBoardViewModel, [Horse], ModelContainer) {
        let container = try ModelContainerFactory.createPreviewContainer()
        let context = container.mainContext
        var result: [Horse] = []

        for entry in horses {
            let horse = Horse(name: entry.name, ownerName: entry.owner)
            let schedule = FeedSchedule()
            horse.feedSchedule = schedule
            context.insert(horse)
            result.append(horse)
        }

        return (FeedBoardViewModel(), result, container)
    }

    // MARK: - filteredHorses: Search Text

    @Test("filteredHorses returns all horses when search text is empty")
    func filteredHorsesNoSearch() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.searchText = ""
        vm.filterFedStatus = .all
        let filtered = vm.filteredHorses(horses)

        #expect(filtered.count == 3)
    }

    @Test("filteredHorses filters by horse name case-insensitively")
    func filteredHorsesByName() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.searchText = "alpha"
        vm.filterFedStatus = .all
        let filtered = vm.filteredHorses(horses)

        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "Alpha")
    }

    @Test("filteredHorses filters by owner name")
    func filteredHorsesByOwner() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.searchText = "Owner B"
        vm.filterFedStatus = .all
        let filtered = vm.filteredHorses(horses)

        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "Bravo")
    }

    @Test("filteredHorses returns empty when no match")
    func filteredHorsesNoMatch() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.searchText = "Zebra"
        vm.filterFedStatus = .all
        let filtered = vm.filteredHorses(horses)

        #expect(filtered.isEmpty)
    }

    @Test("filteredHorses returns results sorted by name")
    func filteredHorsesSorted() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.searchText = ""
        vm.filterFedStatus = .all
        let filtered = vm.filteredHorses(horses)
        let names = filtered.map(\.name)

        #expect(names == ["Alpha", "Bravo", "Charlie"])
    }

    // MARK: - filteredHorses: Fed Status Filter

    @Test("filteredHorses with needsFeeding filter returns unfed horses")
    func filteredHorsesNeedsFeeding() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        // Mark first horse as fed for current slot
        let slot = FeedSlot.current
        if let schedule = horses[0].feedSchedule {
            if slot == .am {
                schedule.amFedToday = true
                schedule.amFedAt = .now
            } else {
                schedule.pmFedToday = true
                schedule.pmFedAt = .now
            }
        }

        vm.filterFedStatus = .needsFeeding
        let filtered = vm.filteredHorses(horses)

        #expect(filtered.count == 2)
        #expect(!filtered.contains(where: { $0.name == "Alpha" }))
    }

    @Test("filteredHorses with fed filter returns only fed horses")
    func filteredHorsesFedFilter() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        // Mark first horse as fed for current slot
        let slot = FeedSlot.current
        if let schedule = horses[0].feedSchedule {
            if slot == .am {
                schedule.amFedToday = true
                schedule.amFedAt = .now
            } else {
                schedule.pmFedToday = true
                schedule.pmFedAt = .now
            }
        }

        vm.filterFedStatus = .fed
        let filtered = vm.filteredHorses(horses)

        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "Alpha")
    }

    // MARK: - isFed

    @Test("isFed returns false for horse with no schedule")
    func isFedNoSchedule() throws {
        let vm = FeedBoardViewModel()
        let horse = Horse(name: "NoSchedule", ownerName: "Test")
        #expect(vm.isFed(horse: horse) == false)
    }

    @Test("isFed returns false for unfed horse")
    func isFedUnfedHorse() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()
        // Fresh schedule — nothing fed
        #expect(vm.isFed(horse: horses[0]) == false)
    }

    @Test("isFed returns true after marking horse as fed")
    func isFedAfterMarking() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        let slot = FeedSlot.current
        if let schedule = horses[0].feedSchedule {
            if slot == .am {
                schedule.amFedToday = true
            } else {
                schedule.pmFedToday = true
            }
        }

        #expect(vm.isFed(horse: horses[0]) == true)
    }

    // MARK: - fedCount

    @Test("fedCount returns 0 when no horses are fed")
    func fedCountZero() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()
        #expect(vm.fedCount(from: horses) == 0)
    }

    @Test("fedCount returns correct count when some horses are fed")
    func fedCountPartial() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        let slot = FeedSlot.current
        // Feed two of three horses
        for horse in horses.prefix(2) {
            if let schedule = horse.feedSchedule {
                if slot == .am {
                    schedule.amFedToday = true
                } else {
                    schedule.pmFedToday = true
                }
            }
        }

        #expect(vm.fedCount(from: horses) == 2)
    }

    @Test("fedCount returns total count when all horses are fed")
    func fedCountAll() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        let slot = FeedSlot.current
        for horse in horses {
            if let schedule = horse.feedSchedule {
                if slot == .am {
                    schedule.amFedToday = true
                } else {
                    schedule.pmFedToday = true
                }
            }
        }

        #expect(vm.fedCount(from: horses) == 3)
    }

    // MARK: - autoResetIfNewDay

    @Test("autoResetIfNewDay resets yesterday's fed status")
    func autoResetResetsYesterday() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        // Simulate yesterday's AM feeding
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        if let schedule = horses[0].feedSchedule {
            schedule.amFedToday = true
            schedule.amFedAt = yesterday
            schedule.pmFedToday = true
            schedule.pmFedAt = yesterday
        }

        vm.autoResetIfNewDay(horses: horses)

        if let schedule = horses[0].feedSchedule {
            #expect(schedule.amFedToday == false)
            #expect(schedule.pmFedToday == false)
            #expect(schedule.amFedAt == nil)
            #expect(schedule.pmFedAt == nil)
        }
    }

    @Test("autoResetIfNewDay does not reset today's fed status")
    func autoResetKeepsToday() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        // Simulate today's AM feeding
        if let schedule = horses[0].feedSchedule {
            schedule.amFedToday = true
            schedule.amFedAt = .now
        }

        vm.autoResetIfNewDay(horses: horses)

        if let schedule = horses[0].feedSchedule {
            #expect(schedule.amFedToday == true)
            #expect(schedule.amFedAt != nil)
        }
    }

    // MARK: - markAllFed / unmarkAllFed

    @Test("markAllFed marks all horses as fed for current slot")
    func markAllFedWorks() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.markAllFed(horses)

        for horse in horses {
            #expect(vm.isFed(horse: horse) == true, "Horse \(horse.name) should be fed")
        }
        #expect(vm.allFedCelebration == true)
    }

    @Test("markAllFed sets fedAt timestamps")
    func markAllFedSetsTimestamps() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.markAllFed(horses)

        let slot = FeedSlot.current
        for horse in horses {
            if let schedule = horse.feedSchedule {
                if slot == .am {
                    #expect(schedule.amFedAt != nil)
                } else {
                    #expect(schedule.pmFedAt != nil)
                }
            }
        }
    }

    @Test("unmarkAllFed clears fed status for all horses")
    func unmarkAllFedWorks() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        // First mark all as fed
        vm.markAllFed(horses)
        #expect(vm.fedCount(from: horses) == 3)

        // Then unmark all
        vm.unmarkAllFed(horses)

        for horse in horses {
            #expect(vm.isFed(horse: horse) == false, "Horse \(horse.name) should not be fed")
        }
        #expect(vm.allFedCelebration == false)
    }

    @Test("unmarkAllFed clears fedAt timestamps")
    func unmarkAllFedClearsTimestamps() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        vm.markAllFed(horses)
        vm.unmarkAllFed(horses)

        let slot = FeedSlot.current
        for horse in horses {
            if let schedule = horse.feedSchedule {
                if slot == .am {
                    #expect(schedule.amFedAt == nil)
                } else {
                    #expect(schedule.pmFedAt == nil)
                }
            }
        }
    }

    @Test("markAllFed does not double-mark already fed horses")
    func markAllFedIdempotent() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()

        // Mark first horse as fed
        let slot = FeedSlot.current
        if let schedule = horses[0].feedSchedule {
            if slot == .am {
                schedule.amFedToday = true
                schedule.amFedAt = .now
            } else {
                schedule.pmFedToday = true
                schedule.pmFedAt = .now
            }
        }

        // markAllFed should not fail or cause issues
        vm.markAllFed(horses)

        #expect(vm.fedCount(from: horses) == 3)
    }

    // MARK: - FedFilter enum

    @Test("FedFilter has all expected cases")
    func fedFilterCases() {
        let cases = FeedBoardViewModel.FedFilter.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.all))
        #expect(cases.contains(.needsFeeding))
        #expect(cases.contains(.fed))
    }

    @Test("FedFilter rawValues are human-readable")
    func fedFilterRawValues() {
        #expect(FeedBoardViewModel.FedFilter.all.rawValue == "All")
        #expect(FeedBoardViewModel.FedFilter.needsFeeding.rawValue == "Needs Feeding")
        #expect(FeedBoardViewModel.FedFilter.fed.rawValue == "Fed")
    }

    // MARK: - hasUnfedHorses

    @Test("hasUnfedHorses returns true when horses are unfed")
    func hasUnfedHorsesTrue() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()
        #expect(vm.hasUnfedHorses(horses) == true)
    }

    @Test("hasUnfedHorses returns false when all horses are fed")
    func hasUnfedHorsesFalse() throws {
        let (vm, horses, _) = try FeedBoardViewModelTests.makeTestSetup()
        vm.markAllFed(horses)
        #expect(vm.hasUnfedHorses(horses) == false)
    }
}
