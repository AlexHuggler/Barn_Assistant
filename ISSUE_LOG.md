# EquineLog Issue Log

iOS-specific technical review identifying crashes, memory leaks, and UX degradation risks.

---

## Critical Issues (Crashes / Data Loss)

### CRIT-001: Force-Try in PreviewContainer Crashes on Model Setup Failure

**File:** `EquineLog/Preview/PreviewContainer.swift:15`

**Code:**
```swift
container = try! ModelContainer(for: schema, configurations: [config])
```

**Impact:** If ModelContainer initialization fails (corrupted state, permission issues, memory pressure), the app crashes immediately with no recovery path.

**Root Cause:** `try!` force-unwrap bypasses error handling.

**Fix:** Wrap in do-catch, provide fallback or fatal error with diagnostic message.

---

### CRIT-002: LocationManager Not Actor-Isolated — Thread-Safety Violation

**File:** `EquineLog/Services/WeatherService.swift:55-89`

**Code:**
```swift
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocation?  // Mutated from background thread
    var errorMessage: String?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first  // CLLocationManager callback on arbitrary thread
    }
}
```

**Impact:** CLLocationManagerDelegate callbacks execute on undefined threads. Mutating `@Observable` properties from non-main threads causes undefined behavior and potential crashes in SwiftUI.

**Root Cause:** No `@MainActor` isolation; delegate methods not dispatched to main thread.

**Fix:** Either make `LocationManager` an actor, add `@MainActor` to the class, or use `DispatchQueue.main.async` in delegate methods.

---

### CRIT-003: No SwiftData Migration Strategy — Schema Changes Break Installs

**File:** `EquineLog/EquineLogApp.swift:8`

**Code:**
```swift
.modelContainer(for: [Horse.self, HealthEvent.self, FeedSchedule.self])
```

**Impact:** Any future schema change (new property, renamed field, relationship change) will cause existing app installations to crash or lose data.

**Root Cause:** No `VersionedSchema` or `SchemaMigrationPlan` configured.

**Fix:** Implement lightweight migration plan before any schema changes ship.

---

### CRIT-004: Photo Loading Silently Fails — Data Appears Lost to User

**File:** `EquineLog/Views/FeedBoard/AddHorseView.swift:234-241`

**Code:**
```swift
private func loadPhoto(from item: PhotosPickerItem?) {
    guard let item else { return }
    Task {
        if let data = try? await item.loadTransferable(type: Data.self) {
            imageData = data
        }
        // Silent failure — no else branch, no error message
    }
}
```

**Impact:** If photo loading fails (permission revoked, corrupted asset, memory pressure), user sees nothing — photo appears to not save.

**Root Cause:** `try?` swallows errors; no user feedback path.

**Fix:** Add error state, show alert on failure, log for diagnostics.

---

## High Priority Issues (Performance / UX Degradation)

### HIGH-001: WeatherService Lacks Throttling — API Rate Limit Risk

**File:** `EquineLog/Views/Weather/WeatherDashboardView.swift:25-30`

**Code:**
```swift
.onChange(of: locationManager.currentLocation) { _, location in
    guard let location else { return }
    Task {
        await weatherService.fetchWeather(for: location)
    }
}
```

**Impact:** LocationManager can fire multiple updates in rapid succession. Each triggers a WeatherKit API call. WeatherKit has rate limits — excessive calls result in temporary bans.

**Root Cause:** No debouncing or caching layer.

**Fix:** Add 15-minute cache with timestamp; throttle fetches to 1 per session unless user explicitly refreshes.

---

### HIGH-002: No MainActor on Photo State Mutation

**File:** `EquineLog/Views/FeedBoard/AddHorseView.swift:237`

**Code:**
```swift
Task {
    if let data = try? await item.loadTransferable(type: Data.self) {
        imageData = data  // @State mutation from Task context
    }
}
```

**Impact:** `@State` mutations should occur on MainActor. While SwiftUI often handles this implicitly, explicit isolation prevents subtle UI glitches.

**Root Cause:** Task inherits caller's actor context, but loadTransferable is async — may complete on different executor.

**Fix:** Add `@MainActor` to the Task or wrap mutation in `await MainActor.run {}`.

---

### HIGH-003: Incomplete Accessibility Coverage (~30%)

**Files:** Multiple views

**Missing Labels:**
- `HorseProfileView.swift:48` — Menu button lacks accessibility label
- `HealthTimelineView.swift:72-83` — Filter chips have no accessibility hints
- `WeatherDashboardView.swift` — Weather card lacks semantic structure
- `AnalyticsDashboardView.swift` — Chart elements not labeled for VoiceOver

**Impact:** VoiceOver users cannot navigate effectively; app fails WCAG 2.1 AA compliance.

**Root Cause:** Accessibility added reactively, not systematically.

**Fix:** Audit all interactive elements; add `.accessibilityLabel()`, `.accessibilityHint()`, and `.accessibilityElement(children:)` as needed.

---

### HIGH-004: No Dynamic Type Scaling for Custom Fonts

**File:** `EquineLog/Theme/EquineTheme.swift:35-41`

**Code:**
```swift
struct EquineFont {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let feedBoard = Font.system(.title3, design: .monospaced, weight: .medium)
    // Fixed sizes — no @ScaledMetric
}
```

**Impact:** Users with accessibility settings (larger text) get standard sizes. App doesn't respect system-wide Dynamic Type preferences.

**Root Cause:** Using fixed Font definitions instead of scaled values.

**Fix:** Use `@ScaledMetric` for spacing; ensure all text uses system font sizes that automatically scale.

---

### HIGH-005: No iPad Layout Support

**Files:** All view files

**Evidence:**
- No `horizontalSizeClass` environment checks
- No `NavigationSplitView` for iPad
- Hardcoded `.frame()` values assume iPhone dimensions
- No sidebar or detail pane patterns

**Impact:** App displays as enlarged iPhone UI on iPad — poor use of screen real estate.

**Root Cause:** MVP prioritized iPhone; no iPad design implemented.

**Fix:** Add `@Environment(\.horizontalSizeClass)` checks; implement `NavigationSplitView` for `.regular` size class.

---

### HIGH-006: Strong Reference Cycle in LocationManager

**File:** `EquineLog/Services/WeatherService.swift:63-68`

**Code:**
```swift
override init() {
    super.init()
    manager.delegate = self  // CLLocationManager holds strong ref to self
}
// No deinit to clean up
```

**Impact:** If LocationManager is recreated (view dismissed/re-presented), old instances may not deallocate until CLLocationManager releases delegate.

**Root Cause:** CLLocationManager retains its delegate; no explicit cleanup.

**Fix:** Add `deinit` that sets `manager.delegate = nil`; or make LocationManager a true singleton.

---

## Medium Priority Issues (Technical Debt / Code Quality)

### MED-001: PreviewContainer Sample Data Uses Relative Dates

**File:** `EquineLog/Preview/PreviewContainer.swift:41-70`

**Code:**
```swift
let farrierEvent = HealthEvent(
    type: .farrier,
    date: calendar.date(byAdding: .weekOfYear, value: -6, to: .now)!,
    nextDueDate: calendar.date(byAdding: .weekOfYear, value: 2, to: .now),
    // ...
)
```

**Impact:** "Overdue" status in previews only accurate at build time. Days later, preview state drifts.

**Root Cause:** Dates calculated relative to `.now` at initialization.

**Fix:** Use fixed dates or create PreviewContainer with configurable "reference date."

---

### MED-002: Duplicated UIImage Construction Pattern

**Files:** `FeedBoardRow.swift:25-27`, `HorseProfileView.swift:94-98`, `AddHorseView.swift:108-113`

**Code Pattern:**
```swift
if let imageData = horse.imageData,
   let uiImage = UIImage(data: imageData) {
    Image(uiImage: uiImage)
} else {
    Image(systemName: "horse.circle.fill")
}
```

**Impact:** Repeated code; inconsistent placeholder handling if one site changes.

**Root Cause:** No shared HorseAvatarView component.

**Fix:** Extract to reusable `HorseAvatarView(horse:size:)` component.

---

### MED-003: HealthEventType Enum Uses String RawValue

**File:** `EquineLog/Models/HealthEvent.swift:57-74`

**Code:**
```swift
enum HealthEventType: String, Codable, CaseIterable, Identifiable {
    case farrier = "Farrier"
    case vet = "Vet"
    case deworming = "Deworming"
    case dental = "Dental"
}
```

**Impact:** Renaming display string breaks stored data. Localization requires separate mapping.

**Root Cause:** Display string used as persistence key.

**Fix:** Use short stable identifiers for rawValue; add separate `displayName` computed property for UI.

---

### MED-004: No Test Coverage

**Files:** None

**Impact:** Regressions go undetected; refactoring is risky; code quality cannot be objectively measured.

**Root Cause:** MVP velocity prioritized shipping over testing.

**Fix:** Add Swift Testing or XCTest targets; start with critical business logic (BlanketRecommendation, FormValidation, date calculations).

---

### MED-005: PDFReportService Has No Error Handling

**File:** `EquineLog/Services/PDFReportService.swift`

**Code:**
```swift
let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
let data = renderer.pdfData { context in
    // All drawing code — no try/catch
}
return data
```

**Impact:** If rendering fails (memory pressure, invalid input), method returns empty or corrupted data.

**Root Cause:** `pdfData(actions:)` doesn't throw, but underlying drawing can fail silently.

**Fix:** Validate output size; add assertion for minimum expected byte count; wrap in Result type.

---

### MED-006: Hardcoded Currency Code

**File:** `EquineLog/Views/Health/AddHealthEventView.swift:91`

**Code:**
```swift
TextField("Cost ($)", value: $cost, format: .currency(code: "USD"))
```

**Impact:** Non-US users see USD symbol; costs don't match their locale.

**Root Cause:** Currency code hardcoded instead of using locale.

**Fix:** Use `Locale.current.currency?.identifier ?? "USD"` or let user configure in settings.

---

### MED-007: Magic Strings for SF Symbols

**Files:** Multiple

**Code Pattern:**
```swift
Image(systemName: "heart.text.clipboard")
Image(systemName: "plus.circle.fill")
Image(systemName: "horse.circle.fill")
```

**Impact:** Typos in symbol names fail silently (show empty image); no compile-time checking.

**Root Cause:** SF Symbols referenced via raw strings.

**Fix:** Create `enum SFSymbol: String` with all used symbols; or use SF Symbols app code generation.

---

### MED-008: LocationManager Instantiated Per View

**File:** `EquineLog/Views/Weather/WeatherDashboardView.swift:7`

**Code:**
```swift
@State private var locationManager = LocationManager()
```

**Impact:** Each time WeatherDashboardView is created, a new LocationManager is created. Multiple CLLocationManager instances waste resources.

**Root Cause:** LocationManager is not a singleton.

**Fix:** Make LocationManager a shared singleton; or inject via Environment.

---

## Summary Table

| ID | Severity | Category | File | Status |
|----|----------|----------|------|--------|
| CRIT-001 | Critical | Error Handling | PreviewContainer.swift | ✅ Fixed |
| CRIT-002 | Critical | Thread Safety | WeatherService.swift | ✅ Fixed |
| CRIT-003 | Critical | Data Migration | EquineLogApp.swift | Open |
| CRIT-004 | Critical | Error Handling | AddHorseView.swift | ✅ Fixed |
| HIGH-001 | High | Performance | WeatherDashboardView.swift | ✅ Fixed |
| HIGH-002 | High | Thread Safety | AddHorseView.swift | ✅ Fixed |
| HIGH-003 | High | Accessibility | Multiple | Open |
| HIGH-004 | High | Accessibility | EquineTheme.swift | Open |
| HIGH-005 | High | UI/UX | Multiple | Open |
| HIGH-006 | High | Memory | WeatherService.swift | ✅ Fixed |
| MED-001 | Medium | Testing | PreviewContainer.swift | Open |
| MED-002 | Medium | DRY | Multiple | Open |
| MED-003 | Medium | Data Model | HealthEvent.swift | Open |
| MED-004 | Medium | Testing | N/A | ✅ Started |
| MED-005 | Medium | Error Handling | PDFReportService.swift | Open |
| MED-006 | Medium | Localization | AddHealthEventView.swift | Open |
| MED-007 | Medium | Type Safety | Multiple | Open |
| MED-008 | Medium | Performance | WeatherDashboardView.swift | ✅ Fixed |

---

## Recommended Fix Order

1. **CRIT-002** — LocationManager thread safety (crash risk)
2. **CRIT-004** — Photo loading error handling (data loss perception)
3. **CRIT-001** — PreviewContainer force-try (dev experience)
4. **HIGH-002** — MainActor photo mutation (UI stability)
5. **HIGH-006** — LocationManager reference cycle (memory)
6. **HIGH-001** — Weather API throttling (rate limits)
7. **MED-004** — Add test infrastructure (foundation for quality)
8. **CRIT-003** — Migration strategy (before any schema changes)
