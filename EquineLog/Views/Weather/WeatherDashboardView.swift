import SwiftUI
import SwiftData

struct WeatherDashboardView: View {
    @Query(sort: \Horse.name) private var horses: [Horse]
    @State private var weatherService = WeatherService()
    private var locationManager: LocationManager { LocationManager.shared }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weatherCard
                    blanketingSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weather")
            .onAppear {
                locationManager.requestLocation()
            }
            .onChange(of: locationManager.currentLocation) { _, location in
                guard let location else { return }
                Task {
                    await weatherService.fetchWeather(for: location)
                }
            }
        }
    }

    // MARK: - Weather Card

    private var weatherCard: some View {
        VStack(spacing: 16) {
            if weatherService.isLoading {
                ProgressView("Fetching weather...")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let errorMsg = weatherService.errorMessage {
                errorView(errorMsg)
            } else if let temp = weatherService.currentTemperatureF {
                currentWeatherDisplay(temp: temp)
            } else {
                requestPermissionView
            }
        }
        .equineCard()
    }

    private func currentWeatherDisplay(temp: Double) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                if let symbol = weatherService.conditionSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 48))
                        .foregroundStyle(Color.hunterGreen)
                        .symbolRenderingMode(.multicolor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(temp))°F")
                        .font(EquineFont.largeTitle)
                        .foregroundStyle(Color.barnText)
                    if let description = weatherService.conditionDescription {
                        Text(description.capitalized)
                            .font(EquineFont.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            HStack(spacing: 20) {
                if let humidity = weatherService.humidity {
                    Label("\(Int(humidity))%", systemImage: "humidity.fill")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)
                }
                if let wind = weatherService.windSpeedMPH {
                    Label("\(Int(wind)) mph", systemImage: "wind")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let updated = weatherService.lastUpdated {
                    Text("Updated \(updated, style: .relative) ago")
                        .font(EquineFont.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.alertRed.opacity(0.6))
            Text(message)
                .font(EquineFont.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                locationManager.requestLocation()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
    }

    private var requestPermissionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.hunterGreen)
            Text("Enable location to get weather-based blanketing recommendations.")
                .font(EquineFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Enable Location") {
                locationManager.requestLocation()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }

    // MARK: - Blanketing Section

    private var blanketingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Blanketing Recommendations")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            if horses.isEmpty {
                Text("Add horses to see personalized blanketing advice.")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
                    .equineCard()
            } else if let temp = weatherService.currentTemperatureF {
                ForEach(horses) { horse in
                    blanketCard(for: horse, temperature: temp)
                }
            } else {
                Text("Waiting for weather data...")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
                    .equineCard()
            }
        }
    }

    private func blanketCard(for horse: Horse, temperature: Double) -> some View {
        let recommendation = BlanketRecommendation.recommend(
            temperatureF: temperature,
            isClipped: horse.isClipped
        )

        return HStack(spacing: 14) {
            Image(systemName: BlanketRecommendation.iconName(for: recommendation))
                .font(.title2)
                .foregroundStyle(Color.hunterGreen)
                .frame(width: 44, height: 44)
                .background(Color.hunterGreen.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(horse.name)
                        .font(EquineFont.headline)
                        .foregroundStyle(Color.barnText)
                    StatusBadge(
                        text: horse.isClipped ? "Clipped" : "Unclipped",
                        color: horse.isClipped ? .saddleBrown : .hunterGreen
                    )
                }

                Text(recommendation.rawValue)
                    .font(EquineFont.feedBoard)
                    .foregroundStyle(Color.saddleBrown)

                Text(BlanketRecommendation.description(for: recommendation))
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .equineCard()
    }
}

#Preview {
    WeatherDashboardView()
        .modelContainer(PreviewContainer.shared.container)
}
