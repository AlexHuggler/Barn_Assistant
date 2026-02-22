import SwiftUI

/// A contextual overlay that guides the user through key features after onboarding.
/// Displays step-by-step tooltips anchored to the current screen content.
struct GuidedTourOverlay: View {
    @Bindable var manager: OnboardingManager
    let onTabChange: (String) -> Void

    var body: some View {
        if let step = manager.guidedTourStep {
            ZStack {
                // Semi-transparent backdrop
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { } // Absorb taps

                // Tooltip card
                VStack(spacing: 0) {
                    if step == .tourComplete || step == .welcomeBack {
                        Spacer()
                    } else {
                        Spacer()
                    }

                    tooltipCard(for: step)
                        .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: step)
        }
    }

    // MARK: - Tooltip Card

    private func tooltipCard(for step: GuidedTourStep) -> some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 40))
                .foregroundStyle(iconColor(for: step))
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            // Title
            Text(step.title)
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)
                .multilineTextAlignment(.center)

            // Message
            Text(step.message)
                .font(EquineFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Step indicator
            stepDots

            // Buttons
            HStack(spacing: 12) {
                if step != .welcomeBack {
                    Button("Skip Tour") {
                        withAnimation {
                            manager.completeGuidedTour()
                        }
                    }
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // Navigate to the tab for the next step before advancing
                        let steps = GuidedTourStep.stepsForUseCase(manager.primaryUseCase)
                        if let currentIndex = steps.firstIndex(of: step),
                           currentIndex + 1 < steps.count {
                            let nextStep = steps[currentIndex + 1]
                            if let tab = nextStep.associatedTab {
                                onTabChange(tab)
                            }
                        }
                        manager.advanceGuidedTour()
                    }
                    HapticManager.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Text(step.buttonLabel)
                        if step != .tourComplete {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                    }
                    .font(EquineFont.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.hunterGreen)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .background(Color.parchment)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
    }

    // MARK: - Step Dots

    private var stepDots: some View {
        let steps = GuidedTourStep.stepsForUseCase(manager.primaryUseCase)
        return HStack(spacing: 6) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                let currentIndex = steps.firstIndex(of: manager.guidedTourStep ?? .welcomeBack) ?? 0
                Circle()
                    .fill(index <= currentIndex ? Color.hunterGreen : Color.hunterGreen.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func iconColor(for step: GuidedTourStep) -> Color {
        switch step {
        case .welcomeBack, .tourComplete: return .hunterGreen
        case .feedBoardIntro, .tapToFeed: return .hunterGreen
        case .healthTab: return .alertRed
        case .weatherTab: return .blue
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        Text("Main App Content")
        GuidedTourOverlay(
            manager: {
                let m = OnboardingManager.shared
                m.guidedTourStep = .feedBoardIntro
                return m
            }(),
            onTabChange: { _ in }
        )
    }
}
