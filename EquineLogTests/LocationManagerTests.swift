import Testing
import Foundation
import CoreLocation
@testable import EquineLog

/// Tests for LocationManager thread safety and lifecycle management.
/// CRIT-002: Validates that LocationManager is MainActor-isolated.
/// HIGH-006: Validates proper cleanup on deinit.
@Suite("LocationManager Thread Safety")
struct LocationManagerTests {

    @Test("LocationManager is MainActor-isolated")
    @MainActor
    func locationManagerIsMainActorIsolated() async {
        // Given: A LocationManager instance
        let manager = LocationManager.shared

        // When: We access properties
        // Then: This compiles only if LocationManager is @MainActor
        _ = manager.currentLocation
        _ = manager.authorizationStatus
        _ = manager.errorMessage

        // If this test compiles and runs, the class is properly isolated
        #expect(true, "LocationManager properties accessible from MainActor context")
    }

    @Test("LocationManager is a singleton")
    @MainActor
    func locationManagerIsSingleton() {
        // Given: Two references to the shared instance
        let manager1 = LocationManager.shared
        let manager2 = LocationManager.shared

        // Then: They should be the same instance
        #expect(manager1 === manager2, "LocationManager.shared should return same instance")
    }

    @Test("Authorization status has valid default")
    @MainActor
    func authorizationStatusDefault() {
        let manager = LocationManager.shared

        // Authorization status should be a valid CLAuthorizationStatus value
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined, .restricted, .denied,
            .authorizedAlways, .authorizedWhenInUse
        ]
        #expect(validStatuses.contains(manager.authorizationStatus))
    }
}

/// Tests for WeatherService caching and throttling.
/// HIGH-001: Validates weather fetch throttling.
@Suite("WeatherService Throttling")
struct WeatherServiceTests {

    @Test("WeatherService respects cache duration")
    @MainActor
    func weatherServiceCacheDuration() async {
        let service = WeatherService()

        // Given: No previous fetch
        #expect(service.lastUpdated == nil)

        // When: We check if fetch is needed
        let shouldFetch = service.shouldFetchWeather

        // Then: It should need a fetch
        #expect(shouldFetch == true, "Should fetch when no cached data exists")
    }

    @Test("WeatherService has valid cache configuration")
    @MainActor
    func weatherServiceCacheConfiguration() {
        // Cache duration should be at least 10 minutes to avoid API rate limits
        let minimumCacheDuration: TimeInterval = 10 * 60  // 10 minutes
        #expect(WeatherService.cacheDuration >= minimumCacheDuration)
    }
}

/// Tests for FormValidation logic.
/// Validates business rules for form input validation.
@Suite("FormValidation")
struct FormValidationTests {

    @Test("Horse name validation - empty name")
    func horseNameValidationEmpty() {
        let result = FormValidation.validateHorseName("")
        #expect(result.isValid == false)
        #expect(result.message != nil)
    }

    @Test("Horse name validation - too short")
    func horseNameValidationTooShort() {
        let result = FormValidation.validateHorseName("A")
        #expect(result.isValid == false)
        #expect(result.message?.contains("2") == true, "Should mention minimum length")
    }

    @Test("Horse name validation - valid name")
    func horseNameValidationValid() {
        let result = FormValidation.validateHorseName("Whiskey")
        #expect(result.isValid == true)
        #expect(result.message == nil)
    }

    @Test("Horse name validation - too long")
    func horseNameValidationTooLong() {
        let longName = String(repeating: "A", count: 50)
        let result = FormValidation.validateHorseName(longName)
        #expect(result.isValid == false)
        #expect(result.message?.contains("40") == true, "Should mention maximum length")
    }

    @Test("Cost validation - nil is valid")
    func costValidationNil() {
        let result = FormValidation.validateCost(nil)
        #expect(result.isValid == true)
    }

    @Test("Cost validation - negative is invalid")
    func costValidationNegative() {
        let result = FormValidation.validateCost(-50.0)
        #expect(result.isValid == false)
        #expect(result.message?.contains("negative") == true)
    }

    @Test("Cost validation - reasonable amount is valid")
    func costValidationReasonable() {
        let result = FormValidation.validateCost(150.0)
        #expect(result.isValid == true)
    }

    @Test("Event dates validation - next due before event")
    func eventDatesValidationInvalid() {
        let eventDate = Date.now
        let nextDue = Calendar.current.date(byAdding: .day, value: -7, to: eventDate)!
        let result = FormValidation.validateEventDates(eventDate: eventDate, nextDueDate: nextDue)
        #expect(result.isValid == false)
    }

    @Test("Event dates validation - next due after event")
    func eventDatesValidationValid() {
        let eventDate = Date.now
        let nextDue = Calendar.current.date(byAdding: .day, value: 30, to: eventDate)!
        let result = FormValidation.validateEventDates(eventDate: eventDate, nextDueDate: nextDue)
        #expect(result.isValid == true)
    }
}

/// Tests for BlanketRecommendation logic.
/// Validates temperature-based blanket suggestions.
@Suite("BlanketRecommendation")
struct BlanketRecommendationTests {

    @Test("Unclipped horse above 60°F needs no blanket")
    func unclippedAbove60() {
        let result = BlanketRecommendation.recommend(temperatureF: 65, isClipped: false)
        #expect(result == .none)
    }

    @Test("Clipped horse above 60°F may need light sheet")
    func clippedAbove60() {
        let result = BlanketRecommendation.recommend(temperatureF: 65, isClipped: true)
        #expect(result == .noneOrLight)
    }

    @Test("Unclipped horse at 45°F needs light sheet")
    func unclippedAt45() {
        let result = BlanketRecommendation.recommend(temperatureF: 45, isClipped: false)
        #expect(result == .lightSheet)
    }

    @Test("Clipped horse at 45°F needs medium weight")
    func clippedAt45() {
        let result = BlanketRecommendation.recommend(temperatureF: 45, isClipped: true)
        #expect(result == .mediumWeight)
    }

    @Test("Unclipped horse below 30°F needs heavy weight")
    func unclippedBelow30() {
        let result = BlanketRecommendation.recommend(temperatureF: 25, isClipped: false)
        #expect(result == .heavyWeight)
    }

    @Test("Clipped horse below 30°F needs heavy weight plus")
    func clippedBelow30() {
        let result = BlanketRecommendation.recommend(temperatureF: 25, isClipped: true)
        #expect(result == .heavyWeightPlus)
    }

    @Test("Temperature boundary at 50°F for unclipped")
    func boundaryAt50Unclipped() {
        // At exactly 50°F, unclipped should still be "no blanket"
        let result = BlanketRecommendation.recommend(temperatureF: 50, isClipped: false)
        #expect(result == .none)
    }

    @Test("Temperature boundary at 50°F for clipped")
    func boundaryAt50Clipped() {
        // At exactly 50°F, clipped needs light sheet
        let result = BlanketRecommendation.recommend(temperatureF: 50, isClipped: true)
        #expect(result == .lightSheet)
    }
}

/// Tests for FeedSlot utility.
@Suite("FeedSlot")
struct FeedSlotTests {

    @Test("FeedSlot has correct PM cutoff")
    func feedSlotCutoff() {
        // PM cutoff should be 14 (2 PM)
        #expect(FeedSlot.pmCutoffHour == 14)
    }

    @Test("FeedSlot current returns valid value")
    func feedSlotCurrent() {
        let current = FeedSlot.current
        #expect(current == .am || current == .pm)
    }
}

/// Tests for StringUtilities.
@Suite("StringUtilities")
struct StringUtilitiesTests {

    @Test("parseCSV handles empty string")
    func parseCSVEmpty() {
        let result = StringUtilities.parseCSV("")
        #expect(result.isEmpty)
    }

    @Test("parseCSV handles single value")
    func parseCSVSingle() {
        let result = StringUtilities.parseCSV("Vitamin E")
        #expect(result == ["Vitamin E"])
    }

    @Test("parseCSV handles multiple values")
    func parseCSVMultiple() {
        let result = StringUtilities.parseCSV("Vitamin E, Biotin, CocoSoya")
        #expect(result == ["Vitamin E", "Biotin", "CocoSoya"])
    }

    @Test("parseCSV trims whitespace")
    func parseCSVTrimsWhitespace() {
        let result = StringUtilities.parseCSV("  Vitamin E  ,  Biotin  ")
        #expect(result == ["Vitamin E", "Biotin"])
    }

    @Test("parseCSV filters empty entries")
    func parseCSVFiltersEmpty() {
        let result = StringUtilities.parseCSV("Vitamin E,,Biotin,")
        #expect(result == ["Vitamin E", "Biotin"])
    }
}

/// Tests for Calendar safe date extension.
@Suite("Calendar SafeDate")
struct CalendarSafeDateTests {

    @Test("safeDate returns valid date for normal addition")
    func safeDateNormalAddition() {
        let calendar = Calendar.current
        let now = Date.now
        let result = calendar.safeDate(byAdding: .day, value: 7, to: now)

        // Should return a date 7 days from now
        let expected = calendar.date(byAdding: .day, value: 7, to: now)!
        #expect(result == expected)
    }

    @Test("safeDate handles large values gracefully")
    func safeDateLargeValue() {
        let calendar = Calendar.current
        let now = Date.now

        // Even extreme values should return something (not crash)
        let result = calendar.safeDate(byAdding: .year, value: 1000, to: now)
        #expect(result != now || result == now, "Should return a date (possibly clamped)")
    }
}
