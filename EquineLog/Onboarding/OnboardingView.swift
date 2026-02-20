import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var manager: OnboardingManager

    @State private var currentStep: OnboardingStep = .welcome
    @State private var barnName = ""
    @State private var selectedHorseCount: HorseCountRange = .oneToThree
    @State private var selectedUseCase: PrimaryUseCase = .personalHorses

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
                    welcomeStep
                        .tag(OnboardingStep.welcome)

                    barnSetupStep
                        .tag(OnboardingStep.barnSetup)

                    useCaseStep
                        .tag(OnboardingStep.useCase)

                    featureHighlightsStep
                        .tag(OnboardingStep.features)

                    quickStartStep
                        .tag(OnboardingStep.quickStart)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

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
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step Views

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon / Logo
            ZStack {
                Circle()
                    .fill(Color.hunterGreen.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "horse.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.hunterGreen)
                    .symbolEffect(.pulse, options: .repeating.speed(0.3))
            }

            VStack(spacing: 12) {
                Text("Welcome to EquineLog")
                    .font(EquineFont.largeTitle)
                    .foregroundStyle(Color.barnText)

                Text("Your complete barn management companion")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Key value props
            VStack(alignment: .leading, spacing: 16) {
                ValuePropRow(icon: "checklist", title: "Track Feeding", description: "Never miss a meal with daily AM/PM tracking")
                ValuePropRow(icon: "heart.text.clipboard", title: "Health Records", description: "Vet, farrier, and dental reminders")
                ValuePropRow(icon: "cloud.sun.fill", title: "Weather Alerts", description: "Smart blanket recommendations")
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var barnSetupStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hunterGreen)

                Text("Tell us about your barn")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("This helps us personalize your experience")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 20) {
                // Barn name (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Barn Name (optional)")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)

                    TextField("e.g., Sunny Meadows Farm", text: $barnName)
                        .textFieldStyle(.roundedBorder)
                        .font(EquineFont.body)
                }

                // Horse count
                VStack(alignment: .leading, spacing: 8) {
                    Text("How many horses?")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(HorseCountRange.allCases) { range in
                            SelectableCard(
                                title: range.displayName,
                                icon: range.icon,
                                isSelected: selectedHorseCount == range
                            ) {
                                selectedHorseCount = range
                                HapticManager.selection()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var useCaseStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.saddleBrown)

                Text("What's your primary focus?")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("We'll highlight the most relevant features")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(PrimaryUseCase.allCases) { useCase in
                    UseCaseCard(
                        useCase: useCase,
                        isSelected: selectedUseCase == useCase
                    ) {
                        selectedUseCase = useCase
                        HapticManager.selection()
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var featureHighlightsStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hunterGreen)

                Text("Key Features for You")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("Based on your \(selectedUseCase.displayName.lowercased()) setup")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "checklist",
                        title: "Daily Feed Board",
                        description: "Track AM and PM feedings at a glance. Mark horses fed with a single tap, and see special instructions for each horse.",
                        color: .hunterGreen
                    )

                    FeatureCard(
                        icon: "heart.text.clipboard",
                        title: "Health Timeline",
                        description: "Never miss a vet visit, farrier appointment, or dental check. Get reminders before events are due.",
                        color: .alertRed
                    )

                    FeatureCard(
                        icon: "doc.on.doc.fill",
                        title: "Feed Templates",
                        description: "Save common feed schedules as templates. Apply them instantly when adding new horses.",
                        color: .saddleBrown
                    )

                    FeatureCard(
                        icon: "cloud.sun.fill",
                        title: "Smart Weather",
                        description: "Get blanket recommendations based on current conditions and whether your horse is clipped.",
                        color: .blue
                    )
                }
                .padding(.horizontal, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var quickStartStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hunterGreen)

                Text("You're all set!")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("Would you like to add your first horse now?")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            // Quick add option
            VStack(spacing: 16) {
                Button {
                    withAnimation {
                        wantsToAddHorse.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: wantsToAddHorse ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(wantsToAddHorse ? Color.hunterGreen : .secondary)
                        Text("Yes, add a horse now")
                            .foregroundStyle(Color.barnText)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                if wantsToAddHorse {
                    VStack(spacing: 12) {
                        TextField("Horse name", text: $horseName)
                            .textFieldStyle(.roundedBorder)
                            .font(EquineFont.body)

                        TextField("Owner name", text: $ownerName)
                            .textFieldStyle(.roundedBorder)
                            .font(EquineFont.body)
                    }
                    .padding()
                    .background(Color.hunterGreen.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 8)

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Tips")
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)

                TipRow(icon: "hand.tap.fill", text: "Tap a horse to mark as fed")
                TipRow(icon: "plus.circle.fill", text: "Use the + button to add horses")
                TipRow(icon: "gearshape.fill", text: "Replay this tutorial in Settings")
            }
            .padding()
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button (except on first step)
            if currentStep != .welcome {
                Button {
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
                    .background(Color.white.opacity(0.8))
                    .clipShape(Capsule())
                }
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
            }

            // Next / Get Started button
            Button {
                if currentStep == .quickStart {
                    completeOnboarding()
                } else {
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
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        // Save preferences
        manager.barnName = barnName
        manager.expectedHorseCount = selectedHorseCount
        manager.primaryUseCase = selectedUseCase

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

        HapticManager.notification(.success)
        manager.completeOnboarding()
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case barnSetup = 1
    case useCase = 2
    case features = 3
    case quickStart = 4

    var id: Int { rawValue }

    var next: OnboardingStep {
        OnboardingStep(rawValue: rawValue + 1) ?? self
    }

    var previous: OnboardingStep {
        OnboardingStep(rawValue: rawValue - 1) ?? self
    }
}

// MARK: - Supporting Views

struct ValuePropRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.hunterGreen)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(EquineFont.headline)
                    .foregroundStyle(Color.barnText)
                Text(description)
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct SelectableCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.hunterGreen)

                Text(title)
                    .font(EquineFont.caption)
                    .foregroundStyle(isSelected ? .white : Color.barnText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.hunterGreen : Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.hunterGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct UseCaseCard: View {
    let useCase: PrimaryUseCase
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: useCase.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.hunterGreen)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(useCase.displayName)
                        .font(EquineFont.headline)
                        .foregroundStyle(isSelected ? .white : Color.barnText)

                    Text(useCase.description)
                        .font(EquineFont.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.hunterGreen : Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(EquineFont.headline)
                    .foregroundStyle(Color.barnText)

                Text(description)
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.hunterGreen)
                .frame(width: 20)

            Text(text)
                .font(EquineFont.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(manager: OnboardingManager.shared)
        .modelContainer(PreviewContainer.shared.container)
}
