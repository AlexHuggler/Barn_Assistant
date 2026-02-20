# EquineLog Issue Log

*Last Updated: February 2026*

iOS-specific technical review identifying crashes, memory leaks, and UX degradation risks.

---

## Critical Issues (Crashes / Data Loss)

### CRIT-001: Force-Try in PreviewContainer Crashes on Model Setup Failure

**File:** `EquineLog/Preview/PreviewContainer.swift`

**Status:** ✅ **FIXED**

**Original Code:**
```swift
container = try! ModelContainer(for: schema, configurations: [config])
```

**Fixed Code:**
```swift
do {
    container = try ModelContainerFactory.createPreviewContainer()
} catch {
    fatalError("""
        PreviewContainer failed to initialize ModelContainer.
        Error: \(error.localizedDescription)
        // ... detailed diagnostic info
        """)
}
```

---

### CRIT-002: LocationManager Not Actor-Isolated — Thread-Safety Violation

**File:** `EquineLog/Services/WeatherService.swift`

**Status:** ✅ **FIXED**

**Solution:** Added `@MainActor` to `LocationManager`, made delegate methods `nonisolated`, and dispatched state changes via `Task { @MainActor in }`.

```swift
@Observable
@MainActor
final class LocationManager: NSObject {
    static let shared = LocationManager()  // Singleton

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        Task { @MainActor in
            self.currentLocation = location
        }
    }
}
```

---

### CRIT-003: No SwiftData Migration Strategy — Schema Changes Break Installs

**File:** `EquineLog/Schema/SchemaVersions.swift`

**Status:** ✅ **FIXED**

**Solution:** Implemented `VersionedSchema` and `SchemaMigrationPlan`:

```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Horse.self, HealthEvent.self, FeedSchedule.self, FeedTemplate.self]
    }
}

enum EquineLogMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
```

---

### CRIT-004: Photo Loading Silently Fails — Data Appears Lost to User

**File:** `EquineLog/Views/FeedBoard/AddHorseView.swift`

**Status:** ✅ **FIXED**

**Solution:** Added error state, loading indicator, and user feedback:

```swift
@State private var photoLoadingError: String?
@State private var isLoadingPhoto = false

private func loadPhoto(from item: PhotosPickerItem?) {
    // ... with proper error handling and MainActor.run for state updates
}
```

---

## High Priority Issues (Performance / UX Degradation)

### HIGH-001: WeatherService Lacks Throttling — API Rate Limit Risk

**File:** `EquineLog/Services/WeatherService.swift`

**Status:** ✅ **FIXED**

**Solution:** Added 15-minute cache with `shouldFetchWeather` throttling:

```swift
static let cacheDuration: TimeInterval = 15 * 60

var shouldFetchWeather: Bool {
    guard let lastUpdated else { return true }
    return Date.now.timeIntervalSince(lastUpdated) > Self.cacheDuration
}
```

---

### HIGH-002: No MainActor on Photo State Mutation

**File:** `EquineLog/Views/FeedBoard/AddHorseView.swift`

**Status:** ✅ **FIXED**

**Solution:** Wrapped state mutations in `await MainActor.run {}`.

---

### HIGH-003: Incomplete Accessibility Coverage

**Status:** ✅ **FIXED** (Core interactive elements)

**Improvements Made:**
- Filter chips have `.accessibilityLabel()` and `.accessibilityAddTraits()`
- Health event rows have `.accessibilityHint("Tap to edit this event")`
- Toast notifications have accessibility labels
- Menu buttons have labels

---

### HIGH-004: No Dynamic Type Scaling for Custom Fonts

**File:** `EquineLog/Theme/EquineTheme.swift`

**Status:** ✅ **FIXED**

**Solution:** All fonts now use semantic text styles that automatically scale:

```swift
struct EquineFont {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let body = Font.system(.body, design: .default, weight: .regular)
    // All use .system() with semantic styles
}
```

---

### HIGH-005: No iPad Layout Support

**File:** `EquineLog/ContentView.swift`

**Status:** ✅ **FIXED**

**Solution:** Added `@Environment(\.horizontalSizeClass)` and `NavigationSplitView` for iPad:

```swift
var body: some View {
    if horizontalSizeClass == .regular {
        iPadLayout  // NavigationSplitView
    } else {
        iPhoneLayout  // TabView
    }
}
```

---

### HIGH-006: Strong Reference Cycle in LocationManager

**File:** `EquineLog/Services/WeatherService.swift`

**Status:** ✅ **FIXED**

**Solution:** Added `deinit` for cleanup and made it a singleton:

```swift
deinit {
    manager.delegate = nil
}
```

---

## Medium Priority Issues (Technical Debt / Code Quality)

### MED-001: PreviewContainer Sample Data Uses Relative Dates

**File:** `EquineLog/Preview/PreviewContainer.swift`

**Status:** ✅ **IMPROVED**

**Current:** Uses `Calendar.safeDate(byAdding:)` for stable date calculations with fallbacks.

---

### MED-002: Duplicated UIImage Construction Pattern

**Files:** `FeedBoardRow.swift`, `HorseProfileView.swift`, `AddHorseView.swift`, `FeedTemplateLibraryView.swift`

**Status:** Open

**Code Pattern:**
```swift
if let imageData = horse.imageData,
   let uiImage = UIImage(data: imageData) {
    Image(uiImage: uiImage)
} else {
    Image(systemName: "horse.circle.fill")
}
```

**Recommendation:** Extract to reusable `HorseAvatarView(horse:size:)` component.

---

### MED-003: HealthEventType Enum Uses String RawValue

**File:** `EquineLog/Models/HealthEvent.swift`

**Status:** Open (Documented Risk)

**Impact:** Renaming display string would break stored data.

**Mitigation:** Display names are stable; localization would require separate mapping.

---

### MED-004: Test Coverage

**Status:** ✅ **IMPLEMENTED**

**File:** `EquineLogTests/LocationManagerTests.swift`

**Coverage:**
- LocationManager thread safety tests
- WeatherService cache tests
- FormValidation unit tests
- BlanketRecommendation logic tests
- FeedSlot utility tests
- StringUtilities tests
- Calendar extension tests

---

### MED-005: PDFReportService Has No Error Handling

**File:** `EquineLog/Services/PDFReportService.swift`

**Status:** Open

**Issue:** `pdfData(actions:)` doesn't throw, but rendering can fail silently.

**Recommendation:** Validate output size; add assertion for minimum expected byte count.

---

### MED-006: Hardcoded Currency Code

**File:** `EquineLog/Views/Health/AddHealthEventView.swift`

**Status:** Open

```swift
TextField("Cost ($)", value: $cost, format: .currency(code: "USD"))
```

**Recommendation:** Use `Locale.current.currency?.identifier ?? "USD"`.

---

### MED-007: Magic Strings for SF Symbols

**Files:** Multiple

**Status:** Open

**Recommendation:** Create `enum SFSymbol: String` for type-safe symbol references.

---

### MED-008: LocationManager Instantiated Per View

**Status:** ✅ **FIXED**

**Solution:** Made `LocationManager` a singleton with `LocationManager.shared`.

---

## New Issues (February 2026 Audit)

### NEW-001: OnboardingManager Lacks @MainActor Isolation

**File:** `EquineLog/Onboarding/OnboardingManager.swift`

**Status:** Open

**Issue:** `OnboardingManager` is a singleton accessed from SwiftUI views but lacks `@MainActor` isolation. While UserDefaults access is thread-safe, the `@Observable` macro may have issues if accessed from background contexts.

**Code:**
```swift
@Observable
final class OnboardingManager {  // Missing @MainActor
    static let shared = OnboardingManager()
    var hasCompletedOnboarding: Bool { ... }
}
```

**Recommendation:** Add `@MainActor` for consistency with other singletons.

**Priority:** Low (UserDefaults is thread-safe, but explicit isolation is cleaner)

---

### NEW-002: HealthEventItem Uses Weak Reference to Horse

**File:** `EquineLog/ViewModels/HealthTimelineViewModel.swift`

**Status:** Open

**Code:**
```swift
struct HealthEventItem: Identifiable {
    let event: HealthEvent
    weak var horse: Horse?  // Weak reference
}
```

**Issue:** `weak var horse: Horse?` in a struct is unusual. Structs don't participate in ARC the same way classes do. The weak reference will become nil if the Horse is deallocated while the item is still in use.

**Impact:** Low — Horse objects are retained by SwiftData query results.

**Recommendation:** Consider making this `let horse: Horse?` (strong) since the Horse is already managed by SwiftData, or pass horse ID and look up when needed.

---

### NEW-003: Onboarding View Missing Some Accessibility Labels

**File:** `EquineLog/Onboarding/OnboardingView.swift`

**Status:** Open

**Issue:** Some interactive elements in onboarding lack accessibility labels:
- Progress indicator capsules
- SelectableCard components (have traits but no explicit label)
- Navigation dots

**Priority:** Medium (onboarding is one-time flow)

---

### NEW-004: FeedTemplate Not in PreviewContainer Sample Data

**File:** `EquineLog/Preview/PreviewContainer.swift`

**Status:** Open

**Issue:** `PreviewContainer` creates sample Horse, HealthEvent, and FeedSchedule data, but no sample `FeedTemplate`. This means FeedTemplateLibraryView previews show empty state.

**Recommendation:** Add sample templates in `PreviewContainer.init()`.

---

## Summary Table

| ID | Severity | Category | File | Status |
|----|----------|----------|------|--------|
| CRIT-001 | Critical | Error Handling | PreviewContainer.swift | ✅ Fixed |
| CRIT-002 | Critical | Thread Safety | WeatherService.swift | ✅ Fixed |
| CRIT-003 | Critical | Data Migration | SchemaVersions.swift | ✅ Fixed |
| CRIT-004 | Critical | Error Handling | AddHorseView.swift | ✅ Fixed |
| HIGH-001 | High | Performance | WeatherService.swift | ✅ Fixed |
| HIGH-002 | High | Thread Safety | AddHorseView.swift | ✅ Fixed |
| HIGH-003 | High | Accessibility | Multiple | ✅ Fixed |
| HIGH-004 | High | Accessibility | EquineTheme.swift | ✅ Fixed |
| HIGH-005 | High | UI/UX | ContentView.swift | ✅ Fixed |
| HIGH-006 | High | Memory | WeatherService.swift | ✅ Fixed |
| MED-001 | Medium | Testing | PreviewContainer.swift | ✅ Improved |
| MED-002 | Medium | DRY | Multiple | Open |
| MED-003 | Medium | Data Model | HealthEvent.swift | Open (Documented) |
| MED-004 | Medium | Testing | N/A | ✅ Implemented |
| MED-005 | Medium | Error Handling | PDFReportService.swift | Open |
| MED-006 | Medium | Localization | AddHealthEventView.swift | Open |
| MED-007 | Medium | Type Safety | Multiple | Open |
| MED-008 | Medium | Performance | WeatherDashboardView.swift | ✅ Fixed |
| NEW-001 | Low | Thread Safety | OnboardingManager.swift | Open |
| NEW-002 | Low | Memory | HealthTimelineViewModel.swift | Open |
| NEW-003 | Medium | Accessibility | OnboardingView.swift | Open |
| NEW-004 | Low | Testing | PreviewContainer.swift | Open |

---

## Recommended Next Steps

### Immediate (Before Next Release)
1. **NEW-001** — Add `@MainActor` to OnboardingManager for consistency
2. **MED-002** — Extract HorseAvatarView component (reduces duplication)
3. **NEW-003** — Add accessibility labels to onboarding elements

### Near-Term
4. **MED-005** — Add basic validation to PDFReportService
5. **MED-006** — Use locale-aware currency formatting
6. **NEW-004** — Add sample FeedTemplate to PreviewContainer

### Long-Term (Tech Debt)
7. **MED-007** — Create SF Symbol enum for type safety
8. **NEW-002** — Evaluate HealthEventItem horse reference pattern
