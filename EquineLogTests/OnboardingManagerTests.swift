import Testing
import Foundation
@testable import EquineLog

/// Tests for OnboardingManager state management, personalization, and guided tour progression.
/// Validates UserDefaults-backed properties, computed recommendations, and tour step ordering.
@Suite("Onboarding Manager Tests")
@MainActor
struct OnboardingManagerTests {

    // MARK: - Helpers

    /// Snapshot of UserDefaults keys used by OnboardingManager so we can restore after tests.
    private static let keys = [
        "hasCompletedOnboarding",
        "hasCompletedGuidedTour",
        "barnName",
        "expectedHorseCount",
        "primaryUseCase",
        "experienceLevel"
    ]

    /// Saves current UserDefaults values for onboarding keys.
    private static func saveDefaults() -> [String: Any?] {
        var snapshot: [String: Any?] = [:]
        for key in keys {
            snapshot[key] = UserDefaults.standard.object(forKey: key)
        }
        return snapshot
    }

    /// Restores UserDefaults values from a snapshot.
    private static func restoreDefaults(_ snapshot: [String: Any?]) {
        for (key, value) in snapshot {
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// Clears all onboarding keys so tests start from a clean slate.
    private static func clearDefaults() {
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - completeOnboarding / resetOnboarding

    @Test("completeOnboarding sets hasCompletedOnboarding to true")
    func completeOnboardingSetsFlag() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }
        OnboardingManagerTests.clearDefaults()

        let manager = OnboardingManager.shared
        manager.resetOnboarding()
        #expect(manager.hasCompletedOnboarding == false)

        manager.completeOnboarding()
        #expect(manager.hasCompletedOnboarding == true)
    }

    @Test("resetOnboarding clears both completion flags and tour step")
    func resetOnboardingClearsState() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.completeOnboarding()
        manager.hasCompletedGuidedTour = true
        manager.guidedTourStep = .feedBoardIntro

        manager.resetOnboarding()

        #expect(manager.hasCompletedOnboarding == false)
        #expect(manager.hasCompletedGuidedTour == false)
        #expect(manager.guidedTourStep == nil)
    }

    // MARK: - recommendedStartTab

    @Test("recommendedStartTab returns stable for personalHorses")
    func recommendedTabPersonalHorses() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .personalHorses
        #expect(manager.recommendedStartTab == "stable")
    }

    @Test("recommendedStartTab returns stable for boardingFacility")
    func recommendedTabBoardingFacility() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .boardingFacility
        #expect(manager.recommendedStartTab == "stable")
    }

    @Test("recommendedStartTab returns health for trainingBarn")
    func recommendedTabTrainingBarn() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .trainingBarn
        #expect(manager.recommendedStartTab == "health")
    }

    @Test("recommendedStartTab returns health for breedingFarm")
    func recommendedTabBreedingFarm() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .breedingFarm
        #expect(manager.recommendedStartTab == "health")
    }

    // MARK: - personalizedFeatures

    @Test("personalizedFeatures returns 4 features for each use case")
    func personalizedFeaturesCount() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared

        for useCase in PrimaryUseCase.allCases {
            manager.primaryUseCase = useCase
            #expect(manager.personalizedFeatures.count == 4,
                    "Expected 4 features for \(useCase.rawValue), got \(manager.personalizedFeatures.count)")
        }
    }

    @Test("personalizedFeatures for personalHorses leads with Daily Feed Board")
    func personalizedFeaturesPersonalHorses() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .personalHorses
        let features = manager.personalizedFeatures

        #expect(features[0].title == "Daily Feed Board")
        #expect(features[0].isPrimary == true)
        #expect(features[1].title == "Smart Weather")
        #expect(features[1].isPrimary == true)
    }

    @Test("personalizedFeatures for boardingFacility leads with Feed Templates")
    func personalizedFeaturesBoardingFacility() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .boardingFacility
        let features = manager.personalizedFeatures

        #expect(features[0].title == "Feed Templates")
        #expect(features[0].isPrimary == true)
    }

    @Test("personalizedFeatures for trainingBarn leads with Health Timeline")
    func personalizedFeaturesTrainingBarn() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .trainingBarn
        let features = manager.personalizedFeatures

        #expect(features[0].title == "Health Timeline")
        #expect(features[0].isPrimary == true)
        #expect(features[1].title == "Cost Analytics")
        #expect(features[1].isPrimary == true)
    }

    @Test("personalizedFeatures for breedingFarm leads with Health Records")
    func personalizedFeaturesBreedingFarm() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .breedingFarm
        let features = manager.personalizedFeatures

        #expect(features[0].title == "Health Records")
        #expect(features[0].isPrimary == true)
    }

    // MARK: - shouldShowGuidedTour

    @Test("shouldShowGuidedTour is true when onboarding complete but tour not complete")
    func shouldShowGuidedTourTrue() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }
        OnboardingManagerTests.clearDefaults()

        let manager = OnboardingManager.shared
        manager.hasCompletedOnboarding = true
        manager.hasCompletedGuidedTour = false

        #expect(manager.shouldShowGuidedTour == true)
    }

    @Test("shouldShowGuidedTour is false when onboarding not complete")
    func shouldShowGuidedTourFalseNoOnboarding() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }
        OnboardingManagerTests.clearDefaults()

        let manager = OnboardingManager.shared
        manager.hasCompletedOnboarding = false
        manager.hasCompletedGuidedTour = false

        #expect(manager.shouldShowGuidedTour == false)
    }

    @Test("shouldShowGuidedTour is false when both onboarding and tour are complete")
    func shouldShowGuidedTourFalseBothComplete() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.hasCompletedOnboarding = true
        manager.hasCompletedGuidedTour = true

        #expect(manager.shouldShowGuidedTour == false)
    }

    // MARK: - GuidedTourStep.stepsForUseCase

    @Test("stepsForUseCase personalHorses includes weatherTab and correct ordering")
    func stepsForPersonalHorses() {
        let steps = GuidedTourStep.stepsForUseCase(.personalHorses)

        #expect(steps.first == .welcomeBack)
        #expect(steps.last == .tourComplete)
        #expect(steps.contains(.weatherTab))
        #expect(steps.contains(.healthTab))
        #expect(steps == [.welcomeBack, .feedBoardIntro, .tapToFeed, .weatherTab, .healthTab, .tourComplete])
    }

    @Test("stepsForUseCase boardingFacility omits weatherTab")
    func stepsForBoardingFacility() {
        let steps = GuidedTourStep.stepsForUseCase(.boardingFacility)

        #expect(steps.first == .welcomeBack)
        #expect(steps.last == .tourComplete)
        #expect(!steps.contains(.weatherTab))
        #expect(steps == [.welcomeBack, .feedBoardIntro, .tapToFeed, .healthTab, .tourComplete])
    }

    @Test("stepsForUseCase trainingBarn leads with healthTab after welcome")
    func stepsForTrainingBarn() {
        let steps = GuidedTourStep.stepsForUseCase(.trainingBarn)

        #expect(steps.first == .welcomeBack)
        #expect(steps[1] == .healthTab, "Training barn should show health tab first")
        #expect(steps.last == .tourComplete)
        #expect(steps == [.welcomeBack, .healthTab, .feedBoardIntro, .tapToFeed, .tourComplete])
    }

    @Test("stepsForUseCase breedingFarm includes weatherTab and healthTab early")
    func stepsForBreedingFarm() {
        let steps = GuidedTourStep.stepsForUseCase(.breedingFarm)

        #expect(steps.first == .welcomeBack)
        #expect(steps[1] == .healthTab)
        #expect(steps.contains(.weatherTab))
        #expect(steps.last == .tourComplete)
        #expect(steps == [.welcomeBack, .healthTab, .feedBoardIntro, .weatherTab, .tourComplete])
    }

    @Test("All use case step lists start with welcomeBack and end with tourComplete")
    func allStepListsBookended() {
        for useCase in PrimaryUseCase.allCases {
            let steps = GuidedTourStep.stepsForUseCase(useCase)
            #expect(steps.first == .welcomeBack, "\(useCase.rawValue) should start with welcomeBack")
            #expect(steps.last == .tourComplete, "\(useCase.rawValue) should end with tourComplete")
        }
    }

    // MARK: - Tour Progression

    @Test("startGuidedTour sets step to welcomeBack")
    func startGuidedTourSetsStep() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.guidedTourStep = nil

        manager.startGuidedTour()

        #expect(manager.guidedTourStep == .welcomeBack)
    }

    @Test("advanceGuidedTour progresses through all steps then completes")
    func advanceGuidedTourFullProgression() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }
        OnboardingManagerTests.clearDefaults()

        let manager = OnboardingManager.shared
        manager.primaryUseCase = .personalHorses

        let expectedSteps = GuidedTourStep.stepsForUseCase(.personalHorses)
        manager.startGuidedTour()

        // Walk through all steps except the last (advancing from last completes the tour)
        for i in 0..<expectedSteps.count - 1 {
            #expect(manager.guidedTourStep == expectedSteps[i],
                    "At index \(i), expected \(expectedSteps[i].rawValue)")
            manager.advanceGuidedTour()
        }

        // After advancing past the last step, the tour should be complete
        #expect(manager.guidedTourStep == nil)
        #expect(manager.hasCompletedGuidedTour == true)
    }

    @Test("advanceGuidedTour with nil step does nothing")
    func advanceGuidedTourFromNil() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }
        OnboardingManagerTests.clearDefaults()

        let manager = OnboardingManager.shared
        manager.guidedTourStep = nil
        manager.hasCompletedGuidedTour = false

        manager.advanceGuidedTour()

        #expect(manager.guidedTourStep == nil)
        #expect(manager.hasCompletedGuidedTour == false, "Should not complete tour when no step is active")
    }

    @Test("completeGuidedTour sets flag and clears step")
    func completeGuidedTourSetsFlag() {
        let snapshot = OnboardingManagerTests.saveDefaults()
        defer { OnboardingManagerTests.restoreDefaults(snapshot) }

        let manager = OnboardingManager.shared
        manager.guidedTourStep = .feedBoardIntro
        manager.hasCompletedGuidedTour = false

        manager.completeGuidedTour()

        #expect(manager.guidedTourStep == nil)
        #expect(manager.hasCompletedGuidedTour == true)
    }

    // MARK: - GuidedTourStep Properties

    @Test("Each GuidedTourStep has non-empty title and message")
    func tourStepProperties() {
        for step in GuidedTourStep.allCases {
            #expect(!step.title.isEmpty, "\(step.rawValue) should have a title")
            #expect(!step.message.isEmpty, "\(step.rawValue) should have a message")
            #expect(!step.icon.isEmpty, "\(step.rawValue) should have an icon")
            #expect(!step.buttonLabel.isEmpty, "\(step.rawValue) should have a button label")
        }
    }

    @Test("associatedTab returns correct tabs for navigation steps")
    func associatedTabValues() {
        #expect(GuidedTourStep.feedBoardIntro.associatedTab == "stable")
        #expect(GuidedTourStep.tapToFeed.associatedTab == "stable")
        #expect(GuidedTourStep.healthTab.associatedTab == "health")
        #expect(GuidedTourStep.weatherTab.associatedTab == "weather")
        #expect(GuidedTourStep.welcomeBack.associatedTab == nil)
        #expect(GuidedTourStep.tourComplete.associatedTab == nil)
    }

    // MARK: - Supporting Types

    @Test("PrimaryUseCase has all four expected cases")
    func primaryUseCaseCases() {
        let cases = PrimaryUseCase.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.personalHorses))
        #expect(cases.contains(.boardingFacility))
        #expect(cases.contains(.trainingBarn))
        #expect(cases.contains(.breedingFarm))
    }

    @Test("ExperienceLevel has three expected cases")
    func experienceLevelCases() {
        let cases = ExperienceLevel.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.newToApps))
        #expect(cases.contains(.someExperience))
        #expect(cases.contains(.techSavvy))
    }

    @Test("HorseCountRange has four expected cases")
    func horseCountRangeCases() {
        let cases = HorseCountRange.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.oneToThree))
        #expect(cases.contains(.fourToTen))
        #expect(cases.contains(.elevenToTwenty))
        #expect(cases.contains(.twentyPlus))
    }
}
