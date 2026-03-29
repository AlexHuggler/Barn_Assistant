import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var manager: OnboardingManager

    @State private var currentStep: OnboardingStep = .welcome
    @State private var barnName = ""
    @State private var selectedHorseCount: HorseCountRange = .oneToThree
    @State private var selectedUseCase: PrimaryUseCase = .personalHorses
    @State private var selectedExperience: ExperienceLevel = .newToApps

    // Quick-add horse state
    @State private var horseName = ""
    @State private var ownerName = ""
    @State private var wantsToAddHorse = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.parchment, Color.parchment.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 16)
                    .padding(.horizontal, 32)

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStepView()
                        .tag(OnboardingStep.welcome)

                    BarnSetupStepView(
                        barnName: $barnName,
                        selectedHorseCount: $selectedHorseCount
                    )
                    .tag(OnboardingStep.barnSetup)

                    UseCaseStepView(selectedUseCase: $selectedUseCase)
                        .tag(OnboardingStep.useCase)

                    ExperienceLevelStepView(selectedExperience: $selectedExperience)
                        .tag(OnboardingStep.experienceLevel)

                    FeatureHighlightsStepView(
                        manager: manager,
                        selectedUseCase: selectedUseCase
                    )
                    .tag(OnboardingStep.features)

                    QuickStartStepView(
                        horseName: $horseName,
                        ownerName: $ownerName,
                        wantsToAddHorse: $wantsToAddHorse,
                        selectedExperience: selectedExperience
                    )
                    .tag(OnboardingStep.quickStart)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentStep)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.hunterGreen : Color.hunterGreen.opacity(0.2))
                    .frame(width: step == currentStep ? 24 : nil, height: 4)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
        .accessibilityValue("\(Int((Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)) * 100))% complete")
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button (except on first step)
            if currentStep != .welcome {
                Button {
                    HapticManager.selection()
                    withAnimation {
                        currentStep = currentStep.previous
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(EquineFont.body)
                    .foregroundStyle(Color.barnText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.parchment.opacity(0.8))
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Go back")
                .accessibilityHint("Return to previous step")
            }

            Spacer()

            // Skip button (on first step only)
            if currentStep == .welcome {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Skip")
                        .font(EquineFont.body)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Skip tutorial")
                .accessibilityHint("Skip onboarding and go directly to the app")
            }

            // Next / Get Started button
            Button {
                if currentStep == .quickStart {
                    completeOnboarding()
                } else {
                    HapticManager.selection()
                    withAnimation {
                        currentStep = currentStep.next
                    }
                }
            } label: {
                HStack {
                    Text(currentStep == .quickStart ? "Get Started" : "Next")
                    if currentStep != .quickStart {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(EquineFont.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.hunterGreen)
                .clipShape(Capsule())
            }
            .accessibilityLabel(currentStep == .quickStart ? "Get Started" : "Next step")
            .accessibilityHint(currentStep == .quickStart ? "Complete onboarding and start using the app" : "Continue to next step")
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        // Save preferences
        manager.barnName = barnName
        manager.expectedHorseCount = selectedHorseCount
        manager.primaryUseCase = selectedUseCase
        manager.experienceLevel = selectedExperience

        // Add quick horse if requested
        if wantsToAddHorse && !horseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let schedule = FeedSchedule()
            let horse = Horse(
                name: horseName.trimmingCharacters(in: .whitespacesAndNewlines),
                ownerName: ownerName.trimmingCharacters(in: .whitespacesAndNewlines),
                feedSchedule: schedule
            )
            modelContext.insert(horse)
        }

        // If "techSavvy", skip the guided tour entirely
        if selectedExperience == .techSavvy {
            manager.hasCompletedGuidedTour = true
        }

        HapticManager.successSequence()
        manager.completeOnboarding()
    }
}

#Preview {
    OnboardingView(manager: OnboardingManager.shared)
        .modelContainer(PreviewContainer.shared.container)
}
