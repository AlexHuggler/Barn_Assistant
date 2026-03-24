import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .stable
    @State private var onboardingManager = OnboardingManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeededDefaultTemplates") private var hasSeededDefaultTemplates = false
    @Query(sort: \Horse.name) private var allHorses: [Horse]
    @State private var notificationWeatherService = WeatherService()

    var body: some View {
        ZStack {
            Group {
                if !onboardingManager.hasCompletedOnboarding {
                    OnboardingView(manager: onboardingManager)
                } else if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            .animation(.easeInOut(duration: 0.3), value: onboardingManager.hasCompletedOnboarding)

            // Guided tour overlay — sits above the main app
            if onboardingManager.hasCompletedOnboarding && onboardingManager.guidedTourStep != nil {
                GuidedTourOverlay(manager: onboardingManager) { tabName in
                    if let tab = AppTab(rawValue: tabName) {
                        withAnimation {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
        .onChange(of: onboardingManager.hasCompletedOnboarding) { _, completed in
            if completed {
                seedDefaultTemplatesIfNeeded()
                // Request notification permission after onboarding completes
                Task {
                    await NotificationService.shared.requestPermission()
                }
                // Start guided tour after a brief delay so the main UI renders first
                if onboardingManager.shouldShowGuidedTour {
                    DispatchQueue.main.asyncAfter(deadline: .now() + ViewConstants.tourStepDelay) {
                        withAnimation {
                            onboardingManager.startGuidedTour()
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && onboardingManager.hasCompletedOnboarding {
                NotificationService.shared.evaluateAllMoments(
                    horses: allHorses,
                    weatherService: notificationWeatherService
                )
            }
        }
        .onAppear {
            seedDefaultTemplatesIfNeeded()
            // Resume guided tour if the user left mid-tour (app restart)
            if onboardingManager.shouldShowGuidedTour && onboardingManager.guidedTourStep == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + ViewConstants.tourStepDelay) {
                    withAnimation {
                        onboardingManager.startGuidedTour()
                    }
                }
            }
        }
    }

    private func seedDefaultTemplatesIfNeeded() {
        guard !hasSeededDefaultTemplates, onboardingManager.hasCompletedOnboarding else { return }
        hasSeededDefaultTemplates = true

        let defaults: [(name: String, description: String, amGrain: String, amHay: String, pmGrain: String, pmHay: String, instructions: String)] = [
            ("Hay Only",
             "Basic hay diet, no grain",
             "", "2 flakes Timothy",
             "", "2 flakes Timothy",
             ""),
            ("Grain + Hay (Standard)",
             "Common daily ration for an average adult horse",
             "2 qt SafeChoice", "2 flakes Timothy",
             "2 qt SafeChoice", "2 flakes Timothy",
             ""),
            ("Light Work",
             "Reduced grain for easy keepers or light riding",
             "1 qt SafeChoice", "2 flakes Mixed",
             "", "2 flakes Mixed",
             "Monitor weight weekly"),
            ("Performance",
             "Higher calorie diet for horses in heavy work",
             "3 qt Ultium", "3 flakes Orchard/Alfalfa mix",
             "3 qt Ultium", "3 flakes Orchard/Alfalfa mix",
             "Electrolytes in water bucket after exercise"),
            ("Senior",
             "Easily digestible ration for older horses",
             "2 qt Senior feed", "2 flakes soft Timothy",
             "2 qt Senior feed", "2 flakes soft Timothy",
             "Soak grain if needed. Monitor teeth.")
        ]

        for t in defaults {
            let template = FeedTemplate(
                name: t.name,
                description: t.description,
                amGrain: t.amGrain,
                amHay: t.amHay,
                pmGrain: t.pmGrain,
                pmHay: t.pmHay,
                specialInstructions: t.instructions
            )
            modelContext.insert(template)
        }
    }

    // MARK: - iPhone Layout (Tab Bar)

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            FeedBoardView()
                .tabItem {
                    Label(AppTab.stable.title, systemImage: AppTab.stable.icon)
                }
                .tag(AppTab.stable)

            HealthTimelineView()
                .tabItem {
                    Label(AppTab.health.title, systemImage: AppTab.health.icon)
                }
                .tag(AppTab.health)

            WeatherDashboardView()
                .tabItem {
                    Label(AppTab.weather.title, systemImage: AppTab.weather.icon)
                }
                .tag(AppTab.weather)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(.hunterGreen)
    }

    // MARK: - iPad Layout (Sidebar)

    private var iPadLayout: some View {
        NavigationSplitView {
            List(AppTab.allCases, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("EquineLog")
            .listStyle(.sidebar)
        } detail: {
            selectedDetailView
        }
        .tint(.hunterGreen)
    }

    @ViewBuilder
    private var selectedDetailView: some View {
        switch selectedTab {
        case .stable:
            FeedBoardView()
        case .health:
            HealthTimelineView()
        case .weather:
            WeatherDashboardView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Tab Definition

enum AppTab: String, CaseIterable, Identifiable {
    case stable
    case health
    case weather
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stable: return "Stable"
        case .health: return "Health"
        case .weather: return "Weather"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .stable: return "house.fill"
        case .health: return "heart.text.clipboard"
        case .weather: return "cloud.sun.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.shared.container)
}
