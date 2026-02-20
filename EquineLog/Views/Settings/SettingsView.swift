import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var horses: [Horse]
    @AppStorage("barnModeUnlocked") private var barnModeUnlocked = false
    @State private var showPaywall = false
    @State private var showOnboardingReplay = false
    @State private var onboardingManager = OnboardingManager.shared

    var body: some View {
        NavigationStack {
            List {
                subscriptionSection
                barnInfoSection
                helpSection
                aboutSection
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .fullScreenCover(isPresented: $showOnboardingReplay) {
                OnboardingReplayView(manager: onboardingManager)
            }
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                Image(systemName: barnModeUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(barnModeUnlocked ? Color.pastureGreen : Color.saddleBrown)
                VStack(alignment: .leading, spacing: 2) {
                    Text(barnModeUnlocked ? "Barn Mode Active" : "Free Plan")
                        .font(EquineFont.headline)
                    Text(barnModeUnlocked
                         ? "Unlimited horses and full features."
                         : "1 horse included. Upgrade for unlimited.")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !barnModeUnlocked {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.saddleBrown)
                        Text("Upgrade to Barn Mode")
                            .font(EquineFont.headline)
                            .foregroundStyle(Color.barnText)
                        Spacer()
                        Text("$19.99/mo")
                            .font(EquineFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Barn Info

    private var barnInfoSection: some View {
        Section("Your Barn") {
            HStack {
                Text("Horses")
                Spacer()
                Text("\(horses.count)")
                    .foregroundStyle(.secondary)
            }

            let overdueCount = horses.flatMap(\.overdueEvents).count
            HStack {
                Text("Overdue Maintenance")
                Spacer()
                Text("\(overdueCount)")
                    .foregroundStyle(overdueCount > 0 ? Color.alertRed : .secondary)
            }

            NavigationLink {
                FeedResetView()
            } label: {
                Label("Reset Daily Feed Status", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: - Help & Tutorial

    private var helpSection: some View {
        Section("Help & Tutorial") {
            Button {
                showOnboardingReplay = true
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(Color.hunterGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Replay Tutorial")
                            .font(EquineFont.headline)
                            .foregroundStyle(Color.barnText)
                        Text("Review the app features and tips")
                            .font(EquineFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            NavigationLink {
                QuickTipsView()
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.saddleBrown)
                    Text("Quick Tips")
                        .foregroundStyle(Color.barnText)
                }
            }

            // Show barn profile info if set
            if !onboardingManager.barnName.isEmpty {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(Color.hunterGreen)
                    Text("Barn")
                    Spacer()
                    Text(onboardingManager.barnName)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0 (MVP)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Built with")
                Spacer()
                Text("SwiftUI + SwiftData")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Onboarding Replay View

struct OnboardingReplayView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var manager: OnboardingManager

    @State private var currentStep: OnboardingStep = .welcome

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.parchment, Color.parchment.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }

                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(OnboardingStep.allCases) { step in
                        Capsule()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.hunterGreen : Color.hunterGreen.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 32)

                // Content - reuse feature highlights
                TabView(selection: $currentStep) {
                    replayWelcome
                        .tag(OnboardingStep.welcome)

                    replayFeedBoard
                        .tag(OnboardingStep.barnSetup)

                    replayHealthTimeline
                        .tag(OnboardingStep.useCase)

                    replayTemplates
                        .tag(OnboardingStep.features)

                    replayWeather
                        .tag(OnboardingStep.quickStart)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation dots
                HStack(spacing: 8) {
                    ForEach(OnboardingStep.allCases) { step in
                        Circle()
                            .fill(step == currentStep ? Color.hunterGreen : Color.hunterGreen.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation {
                                    currentStep = step
                                }
                            }
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var replayWelcome: some View {
        FeatureTutorialCard(
            icon: "horse.circle.fill",
            iconColor: .hunterGreen,
            title: "Welcome to EquineLog",
            description: "Your complete barn management companion. Let's walk through the key features that will make managing your horses easier.",
            tips: [
                "Swipe left to see each feature",
                "Close anytime to return to the app"
            ]
        )
    }

    private var replayFeedBoard: some View {
        FeatureTutorialCard(
            icon: "checklist",
            iconColor: .hunterGreen,
            title: "Daily Feed Board",
            description: "Track AM and PM feedings for all your horses in one place. Mark horses as fed with a single tap.",
            tips: [
                "Tap the circle to mark a horse as fed",
                "Use 'Mark All Fed' for quick bulk updates",
                "Undo accidental taps with the undo banner",
                "See special instructions at a glance"
            ]
        )
    }

    private var replayHealthTimeline: some View {
        FeatureTutorialCard(
            icon: "heart.text.clipboard",
            iconColor: .alertRed,
            title: "Health Timeline",
            description: "Never miss an appointment. Track vet visits, farrier schedules, dental checks, and vaccinations with automatic reminders.",
            tips: [
                "Filter by event type or specific horse",
                "Tap any event to edit details",
                "Overdue items appear at the top",
                "Next due dates are auto-calculated"
            ]
        )
    }

    private var replayTemplates: some View {
        FeatureTutorialCard(
            icon: "doc.on.doc.fill",
            iconColor: .saddleBrown,
            title: "Feed Templates",
            description: "Save common feed schedules as reusable templates. Perfect for boarding facilities or when adding multiple horses with similar needs.",
            tips: [
                "Create templates from existing schedules",
                "Apply templates when adding new horses",
                "Templates track AM/PM grain, hay, supplements",
                "Most-used templates appear first"
            ]
        )
    }

    private var replayWeather: some View {
        FeatureTutorialCard(
            icon: "cloud.sun.fill",
            iconColor: .blue,
            title: "Smart Weather",
            description: "Get weather-based blanket recommendations tailored to each horse. Knows whether your horse is clipped for more accurate suggestions.",
            tips: [
                "View current conditions and forecast",
                "Recommendations adjust for clipped horses",
                "Check wind chill for cold weather prep",
                "Plan ahead with 5-day forecast"
            ]
        )
    }
}

struct FeatureTutorialCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let tips: [String]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(iconColor)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))

                // Title and description
                VStack(spacing: 12) {
                    Text(title)
                        .font(EquineFont.title)
                        .foregroundStyle(Color.barnText)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(EquineFont.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tips")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)

                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(iconColor)

                            Text(tip)
                                .font(EquineFont.body)
                                .foregroundStyle(Color.barnText)

                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Quick Tips View

struct QuickTipsView: View {
    var body: some View {
        List {
            Section("Feed Board") {
                TipDetailRow(icon: "hand.tap.fill", color: .hunterGreen, title: "Quick Feed Toggle", description: "Tap the circle next to a horse's name to toggle their fed status for the current time slot.")

                TipDetailRow(icon: "checkmark.circle.fill", color: .pastureGreen, title: "Mark All Fed", description: "Use the 'Mark All Fed' button at the top to quickly mark all horses as fed.")

                TipDetailRow(icon: "arrow.uturn.backward.circle.fill", color: .saddleBrown, title: "Undo Mistakes", description: "Accidentally marked the wrong horse? An undo banner appears for a few seconds after each tap.")
            }

            Section("Health Tracking") {
                TipDetailRow(icon: "calendar.badge.clock", color: .alertRed, title: "Never Miss Appointments", description: "Log health events with their next due date. Overdue items are highlighted in red.")

                TipDetailRow(icon: "sparkles", color: .hunterGreen, title: "Auto-Calculate Due Dates", description: "EquineLog suggests the next due date based on typical schedules (6 weeks for farrier, etc.).")

                TipDetailRow(icon: "line.3.horizontal.decrease.circle.fill", color: .saddleBrown, title: "Filter Events", description: "Filter health events by type (Vet, Farrier, etc.) or by specific horse.")
            }

            Section("Templates") {
                TipDetailRow(icon: "doc.badge.plus", color: .saddleBrown, title: "Save Templates", description: "In Edit Feed Schedule, tap 'Save as Template' to create a reusable feed configuration.")

                TipDetailRow(icon: "doc.on.doc.fill", color: .hunterGreen, title: "Apply Templates", description: "When adding a new horse, use 'Apply Feed Template' to quickly fill in the feed schedule.")
            }

            Section("Weather") {
                TipDetailRow(icon: "thermometer.snowflake", color: .blue, title: "Clipping Matters", description: "Mark horses as 'clipped' in their profile for more accurate blanket recommendations.")
            }
        }
        .navigationTitle("Quick Tips")
        .listStyle(.insetGrouped)
    }
}

struct TipDetailRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(EquineFont.headline)
                    .foregroundStyle(Color.barnText)

                Text(description)
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Feed Reset View

struct FeedResetView: View {
    @Query(sort: \Horse.name) private var horses: [Horse]
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false

    var body: some View {
        List {
            Section {
                Text("Reset the 'fed' status for all horses. Use this at the start of a new day.")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showConfirmation = true
                } label: {
                    Label("Reset All Feeds", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Reset Feeds")
        .confirmationDialog(
            "Reset All Feeds",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset for \(horses.count) horse\(horses.count == 1 ? "" : "s")", role: .destructive) {
                resetAllFeeds()
                HapticManager.notification(.success)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will mark all horses as unfed for the current feeding slot. This is typically done at the start of a new day.")
        }
    }

    private func resetAllFeeds() {
        for horse in horses {
            horse.feedSchedule?.resetDailyStatus()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewContainer.shared.container)
}
