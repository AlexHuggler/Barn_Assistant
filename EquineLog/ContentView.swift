import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .stable
    @State private var onboardingManager = OnboardingManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if !onboardingManager.hasCompletedOnboarding {
                OnboardingView(manager: onboardingManager)
            } else if horizontalSizeClass == .regular {
                // iPad: Sidebar navigation
                iPadLayout
            } else {
                // iPhone: Tab bar navigation
                iPhoneLayout
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.hasCompletedOnboarding)
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
