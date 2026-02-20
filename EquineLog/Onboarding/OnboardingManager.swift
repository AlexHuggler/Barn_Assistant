import Foundation
import Observation

/// Manages onboarding state and user preferences gathered during setup.
@Observable
final class OnboardingManager {
    // MARK: - Singleton

    static let shared = OnboardingManager()

    // MARK: - Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let barnName = "barnName"
        static let horseCount = "expectedHorseCount"
        static let primaryUseCase = "primaryUseCase"
    }

    // MARK: - Stored Properties

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var barnName: String {
        get { UserDefaults.standard.string(forKey: Keys.barnName) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.barnName) }
    }

    var expectedHorseCount: HorseCountRange {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.horseCount) ?? ""
            return HorseCountRange(rawValue: raw) ?? .oneToThree
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.horseCount) }
    }

    var primaryUseCase: PrimaryUseCase {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.primaryUseCase) ?? ""
            return PrimaryUseCase(rawValue: raw) ?? .personalHorses
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.primaryUseCase) }
    }

    // MARK: - Methods

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    private init() {}
}

// MARK: - Supporting Types

enum HorseCountRange: String, CaseIterable, Identifiable {
    case oneToThree = "1-3"
    case fourToTen = "4-10"
    case elevenToTwenty = "11-20"
    case twentyPlus = "20+"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneToThree: return "1-3 horses"
        case .fourToTen: return "4-10 horses"
        case .elevenToTwenty: return "11-20 horses"
        case .twentyPlus: return "20+ horses"
        }
    }

    var icon: String {
        switch self {
        case .oneToThree: return "1.circle.fill"
        case .fourToTen: return "5.circle.fill"
        case .elevenToTwenty: return "15.circle.fill"
        case .twentyPlus: return "infinity.circle.fill"
        }
    }
}

enum PrimaryUseCase: String, CaseIterable, Identifiable {
    case personalHorses = "personal"
    case boardingFacility = "boarding"
    case trainingBarn = "training"
    case breedingFarm = "breeding"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .personalHorses: return "Personal Horses"
        case .boardingFacility: return "Boarding Facility"
        case .trainingBarn: return "Training Barn"
        case .breedingFarm: return "Breeding Farm"
        }
    }

    var description: String {
        switch self {
        case .personalHorses: return "Managing my own horses"
        case .boardingFacility: return "Running a boarding operation"
        case .trainingBarn: return "Training horses professionally"
        case .breedingFarm: return "Breeding and foaling"
        }
    }

    var icon: String {
        switch self {
        case .personalHorses: return "heart.fill"
        case .boardingFacility: return "building.2.fill"
        case .trainingBarn: return "figure.equestrian.sports"
        case .breedingFarm: return "leaf.fill"
        }
    }

    var recommendedFeatures: [String] {
        switch self {
        case .personalHorses:
            return ["Feed tracking", "Health reminders", "Weather alerts"]
        case .boardingFacility:
            return ["Multi-horse management", "Feed templates", "Owner records"]
        case .trainingBarn:
            return ["Health tracking", "Exercise logs", "Cost tracking"]
        case .breedingFarm:
            return ["Health records", "Vet visit tracking", "Due date reminders"]
        }
    }
}
