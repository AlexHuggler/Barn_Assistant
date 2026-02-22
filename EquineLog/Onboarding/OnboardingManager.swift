import Foundation
import Observation
import SwiftUI

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
        static let hasCompletedGuidedTour = "hasCompletedGuidedTour"
        static let experienceLevel = "experienceLevel"
    }

    // MARK: - Stored Properties

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var hasCompletedGuidedTour: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedGuidedTour) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedGuidedTour) }
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

    var experienceLevel: ExperienceLevel {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.experienceLevel) ?? ""
            return ExperienceLevel(rawValue: raw) ?? .newToApps
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Keys.experienceLevel) }
    }

    // MARK: - Guided Tour State (transient, not persisted)

    var guidedTourStep: GuidedTourStep?
    var shouldShowGuidedTour: Bool {
        hasCompletedOnboarding && !hasCompletedGuidedTour
    }

    // MARK: - Personalization

    /// Returns the recommended starting tab based on use case.
    var recommendedStartTab: String {
        switch primaryUseCase {
        case .personalHorses, .boardingFacility: return "stable"
        case .trainingBarn, .breedingFarm: return "health"
        }
    }

    /// Returns personalized feature highlights ordered by relevance.
    var personalizedFeatures: [PersonalizedFeature] {
        switch primaryUseCase {
        case .personalHorses:
            return [
                PersonalizedFeature(icon: "checklist", title: "Daily Feed Board", description: "Track AM and PM feedings with one tap. Never miss a meal.", color: .hunterGreen, isPrimary: true),
                PersonalizedFeature(icon: "cloud.sun.fill", title: "Smart Weather", description: "Get blanket recommendations tailored to each horse's clip status.", color: .blue, isPrimary: true),
                PersonalizedFeature(icon: "heart.text.clipboard", title: "Health Reminders", description: "Auto-scheduled farrier, vet, dental, and deworming reminders.", color: .alertRed, isPrimary: false),
                PersonalizedFeature(icon: "chart.bar.fill", title: "Cost Insights", description: "Track spending and spot trends across your horses.", color: .saddleBrown, isPrimary: false)
            ]
        case .boardingFacility:
            return [
                PersonalizedFeature(icon: "doc.on.doc.fill", title: "Feed Templates", description: "Create reusable schedules. Apply with one tap when onboarding new horses.", color: .saddleBrown, isPrimary: true),
                PersonalizedFeature(icon: "checklist", title: "Feed Board", description: "AM/PM feeding dashboard for all horses. Staff can mark feeds in seconds.", color: .hunterGreen, isPrimary: true),
                PersonalizedFeature(icon: "doc.richtext", title: "Owner Reports", description: "Generate PDF reports for horse owners with health and cost summaries.", color: .blue, isPrimary: false),
                PersonalizedFeature(icon: "heart.text.clipboard", title: "Health Timeline", description: "Track vet and farrier schedules across all horses.", color: .alertRed, isPrimary: false)
            ]
        case .trainingBarn:
            return [
                PersonalizedFeature(icon: "heart.text.clipboard", title: "Health Timeline", description: "Track vet visits, farrier schedules, and costs for each horse in training.", color: .alertRed, isPrimary: true),
                PersonalizedFeature(icon: "chart.bar.fill", title: "Cost Analytics", description: "Monitor expenses per horse. Project annual costs and spot overspending.", color: .saddleBrown, isPrimary: true),
                PersonalizedFeature(icon: "checklist", title: "Feed Board", description: "Ensure every horse gets the right feed at the right time.", color: .hunterGreen, isPrimary: false),
                PersonalizedFeature(icon: "cloud.sun.fill", title: "Weather Alerts", description: "Plan blankets and turnout around real-time weather.", color: .blue, isPrimary: false)
            ]
        case .breedingFarm:
            return [
                PersonalizedFeature(icon: "heart.text.clipboard", title: "Health Records", description: "Comprehensive vet and health tracking per horse. Auto-calculated due dates.", color: .alertRed, isPrimary: true),
                PersonalizedFeature(icon: "calendar.badge.clock", title: "Due Date Tracking", description: "Automatic reminders for deworming, dental, and vet checkups.", color: .hunterGreen, isPrimary: true),
                PersonalizedFeature(icon: "checklist", title: "Feed Board", description: "Track special feeding needs for mares, foals, and stallions.", color: .saddleBrown, isPrimary: false),
                PersonalizedFeature(icon: "doc.richtext", title: "Owner Reports", description: "PDF reports with full health history for buyers and owners.", color: .blue, isPrimary: false)
            ]
        }
    }

    // MARK: - Methods

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func completeGuidedTour() {
        guidedTourStep = nil
        hasCompletedGuidedTour = true
    }

    func startGuidedTour() {
        guidedTourStep = .welcomeBack
    }

    func advanceGuidedTour() {
        guard let current = guidedTourStep else { return }
        let allSteps = GuidedTourStep.stepsForUseCase(primaryUseCase)
        guard let index = allSteps.firstIndex(of: current), index + 1 < allSteps.count else {
            completeGuidedTour()
            return
        }
        guidedTourStep = allSteps[index + 1]
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasCompletedGuidedTour = false
        guidedTourStep = nil
    }

    private init() {}
}

// MARK: - Personalized Feature

struct PersonalizedFeature: Identifiable {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isPrimary: Bool
    var id: String { title }
}

// MARK: - Experience Level

enum ExperienceLevel: String, CaseIterable, Identifiable {
    case newToApps = "new"
    case someExperience = "some"
    case techSavvy = "savvy"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newToApps: return "Show me everything"
        case .someExperience: return "Just the basics"
        case .techSavvy: return "I'll figure it out"
        }
    }

    var description: String {
        switch self {
        case .newToApps: return "Full guided tour with step-by-step tips"
        case .someExperience: return "Quick highlights of key features"
        case .techSavvy: return "Skip the tour, jump right in"
        }
    }

    var icon: String {
        switch self {
        case .newToApps: return "hand.raised.fingers.spread.fill"
        case .someExperience: return "bolt.fill"
        case .techSavvy: return "hare.fill"
        }
    }
}

// MARK: - Guided Tour Steps

enum GuidedTourStep: String, CaseIterable, Identifiable, Equatable {
    case welcomeBack
    case feedBoardIntro
    case tapToFeed
    case healthTab
    case weatherTab
    case tourComplete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .welcomeBack: return "Welcome to Your Barn!"
        case .feedBoardIntro: return "Your Feed Board"
        case .tapToFeed: return "Mark as Fed"
        case .healthTab: return "Health Timeline"
        case .weatherTab: return "Weather & Blankets"
        case .tourComplete: return "You're All Set!"
        }
    }

    var message: String {
        switch self {
        case .welcomeBack: return "Let's take a quick look around so you can start managing your barn right away."
        case .feedBoardIntro: return "This is your daily command center. Each row shows a horse's feed schedule for the current slot."
        case .tapToFeed: return "Tap the circle next to a horse to mark them as fed. You can undo if you tap by accident."
        case .healthTab: return "Track vet visits, farrier schedules, and more. Overdue items appear at the top in red."
        case .weatherTab: return "Get blanket recommendations based on real weather and your horse's clip status."
        case .tourComplete: return "You're ready to go! Explore at your own pace. You can always replay this from Settings."
        }
    }

    var icon: String {
        switch self {
        case .welcomeBack: return "hand.wave.fill"
        case .feedBoardIntro: return "checklist"
        case .tapToFeed: return "hand.tap.fill"
        case .healthTab: return "heart.text.clipboard"
        case .weatherTab: return "cloud.sun.fill"
        case .tourComplete: return "flag.checkered"
        }
    }

    var buttonLabel: String {
        switch self {
        case .welcomeBack: return "Let's Go"
        case .feedBoardIntro, .tapToFeed, .healthTab, .weatherTab: return "Next"
        case .tourComplete: return "Start Managing"
        }
    }

    /// Returns a use-case-specific ordering of tour steps.
    static func stepsForUseCase(_ useCase: PrimaryUseCase) -> [GuidedTourStep] {
        switch useCase {
        case .personalHorses:
            return [.welcomeBack, .feedBoardIntro, .tapToFeed, .weatherTab, .healthTab, .tourComplete]
        case .boardingFacility:
            return [.welcomeBack, .feedBoardIntro, .tapToFeed, .healthTab, .tourComplete]
        case .trainingBarn:
            return [.welcomeBack, .healthTab, .feedBoardIntro, .tapToFeed, .tourComplete]
        case .breedingFarm:
            return [.welcomeBack, .healthTab, .feedBoardIntro, .weatherTab, .tourComplete]
        }
    }

    /// The tab that should be active during this step, if any.
    var associatedTab: String? {
        switch self {
        case .feedBoardIntro, .tapToFeed: return "stable"
        case .healthTab: return "health"
        case .weatherTab: return "weather"
        case .welcomeBack, .tourComplete: return nil
        }
    }
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
