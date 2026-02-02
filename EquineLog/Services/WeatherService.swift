import Foundation
import WeatherKit
import CoreLocation
import Observation

@Observable
final class WeatherService {
    var currentTemperatureF: Double?
    var conditionDescription: String?
    var conditionSymbol: String?
    var humidity: Double?
    var windSpeedMPH: Double?
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    private let weatherService = WeatherKit.WeatherService.shared

    @MainActor
    func fetchWeather(for location: CLLocation) async {
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
}

// MARK: - Location Manager

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
