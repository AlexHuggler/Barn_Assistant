import Foundation
import WeatherKit
import CoreLocation
import Observation

// MARK: - WeatherService

@Observable
@MainActor
final class WeatherService {
    var currentTemperatureF: Double?
    var conditionDescription: String?
    var conditionSymbol: String?
    var humidity: Double?
    var windSpeedMPH: Double?
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    /// Cache duration in seconds (15 minutes) to avoid WeatherKit rate limits.
    static let cacheDuration: TimeInterval = 15 * 60

    private let weatherService = WeatherKit.WeatherService.shared

    /// Returns true if a new fetch is needed (no cache or cache expired).
    var shouldFetchWeather: Bool {
        guard let lastUpdated else { return true }
        return Date.now.timeIntervalSince(lastUpdated) > Self.cacheDuration
    }

    func fetchWeather(for location: CLLocation) async {
        // Throttle: skip if cache is still valid
        guard shouldFetchWeather else { return }

        isLoading = true
        errorMessage = nil

        do {
            let weather = try await weatherService.weather(for: location)
            let current = weather.currentWeather

            currentTemperatureF = current.temperature.converted(to: .fahrenheit).value
            conditionDescription = current.condition.description
            conditionSymbol = current.symbolName
            humidity = current.humidity * 100
            windSpeedMPH = current.wind.speed.converted(to: .milesPerHour).value
            lastUpdated = .now
        } catch {
            errorMessage = "Unable to fetch weather: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Forces a refresh, bypassing cache.
    func forceRefresh(for location: CLLocation) async {
        lastUpdated = nil
        await fetchWeather(for: location)
    }
}

// MARK: - LocationManager

/// Thread-safe location manager with MainActor isolation.
/// Uses singleton pattern to avoid multiple CLLocationManager instances.
///
/// - Important: All properties are isolated to MainActor to prevent
///   race conditions from CLLocationManagerDelegate callbacks.
@Observable
@MainActor
final class LocationManager: NSObject {
    /// Shared singleton instance.
    static let shared = LocationManager()

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?

    private let manager = CLLocationManager()

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    deinit {
        // Clean up delegate reference to break potential retain cycle
        manager.delegate = nil
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    /// Called when location updates are available.
    /// - Note: Dispatched to MainActor to ensure thread-safe property mutation.
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    /// Called when location fetch fails.
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.errorMessage = message
        }
    }

    /// Called when authorization status changes.
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }
}
