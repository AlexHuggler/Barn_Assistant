# EquineLog Project Architecture Map

## 1. Framework Analysis

| Category | Technology | Version Target |
|----------|------------|----------------|
| **UI Framework** | SwiftUI (primary) | iOS 17+ |
| **UIKit Bridging** | PDF generation, Haptics, Share sheet | Selective |
| **Persistence** | SwiftData | iOS 17+ |
| **Weather** | WeatherKit | iOS 16+ |
| **Location** | CoreLocation | iOS 2+ |
| **Charts** | Swift Charts | iOS 16+ |
| **Photos** | PhotosUI (PhotosPicker) | iOS 16+ |

### Dependency Management
- **System:** Pure Apple frameworks only
- **No external dependencies** (no SPM, CocoaPods, or Carthage)
- **Minimum deployment:** iOS 17+ (required for SwiftData + @Observable)

---

## 2. Architecture Pattern

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              MVVM + Services                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│   │    Views     │───▶│  ViewModels  │───▶│      SwiftData Models    │  │
│   │  (SwiftUI)   │    │ (@Observable)│    │        (@Model)          │  │
│   └──────────────┘    └──────────────┘    └──────────────────────────┘  │
│          │                                            ▲                  │
│          │                                            │                  │
│          ▼                                            │                  │
│   ┌──────────────┐                         ┌──────────────────────────┐  │
│   │   Services   │                         │     ModelContainer       │  │
│   │ (Weather/PDF)│                         │    (Persistence Root)    │  │
│   └──────────────┘                         └──────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Pattern: **MVVM with Lightweight ViewModels**

| Component | Pattern | Implementation |
|-----------|---------|----------------|
| Views | Pure SwiftUI declarative | `@Query`, `@Environment`, `@State` |
| ViewModels | `@Observable` (iOS 17+) | Direct property binding, no `@Published` |
| Models | SwiftData `@Model` | Automatic persistence, relationships |
| Services | Static/Singleton-like | Stateless utilities + stateful weather |

---

## 3. Module Dependency Graph

```
EquineLogApp.swift (ENTRY POINT)
        │
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          ContentView.swift                           │
│                     (TabView Navigation Hub)                         │
└─────────────────────────────────────────────────────────────────────┘
        │
        ├─────────────────┬─────────────────┬─────────────────┐
        ▼                 ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  FeedBoard    │ │ HealthTimeline│ │WeatherDashboard│ │   Settings    │
│    Tab        │ │     Tab       │ │     Tab        │ │     Tab       │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘
        │                 │                 │                 │
        ▼                 ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│FeedBoardView  │ │HealthTimeline │ │WeatherDashboard│ │ SettingsView  │
│FeedBoardRow   │ │     View      │ │     View       │ │ PaywallView   │
│AddHorseView   │ │AddHealthEvent │ │                │ │ FeedResetView │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘
        │                 │                 │
        └────────┬────────┴────────┬────────┘
                 ▼                 ▼
        ┌───────────────┐ ┌───────────────┐
        │HorseProfileView│ │   Services    │
        │EditFeedSchedule│ │WeatherService │
        │AnalyticsDash   │ │PDFReportService│
        └───────────────┘ └───────────────┘
                 │
                 ▼
        ┌───────────────────────────────────────┐
        │           SwiftData Models            │
        │   Horse ◀──▶ HealthEvent             │
        │     │                                 │
        │     ▼                                 │
        │   FeedSchedule                        │
        └───────────────────────────────────────┘
                 │
                 ▼
        ┌───────────────────────────────────────┐
        │         Shared Utilities              │
        │   FeedSlot │ StringUtilities          │
        │   FormValidation │ HapticManager      │
        │   CycleThreshold │ Calendar.safeDate  │
        └───────────────────────────────────────┘
```

---

## 4. Entry Point

**File:** `EquineLog/EquineLogApp.swift`

```swift
@main
struct EquineLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Horse.self, HealthEvent.self, FeedSchedule.self])
    }
}
```

### App Lifecycle
1. `@main` attribute designates entry point
2. `WindowGroup` creates the root window
3. `.modelContainer()` injects SwiftData persistence
4. `ContentView` renders the `TabView` navigation

---

## 5. Persistence Layer

### SwiftData Schema

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ModelContainer                               │
│                    (Automatic SQLite backend)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────┐       ┌────────────────┐                        │
│  │     Horse      │───────│  HealthEvent   │  (One-to-Many)         │
│  │    @Model      │       │    @Model      │                        │
│  ├────────────────┤       ├────────────────┤                        │
│  │ id: UUID       │       │ id: UUID       │                        │
│  │ name: String   │       │ type: Enum     │                        │
│  │ ownerName      │       │ date: Date     │                        │
│  │ imageData?     │◀──────│ horse: Horse?  │  (Inverse)             │
│  │ isClipped: Bool│       │ notes: String  │                        │
│  │ dateAdded: Date│       │ nextDueDate?   │                        │
│  │ healthEvents[] │       │ cost: Double?  │                        │
│  │ feedSchedule?  │       │ providerName?  │                        │
│  └────────────────┘       └────────────────┘                        │
│          │                                                           │
│          │ (One-to-One Optional)                                     │
│          ▼                                                           │
│  ┌────────────────┐                                                  │
│  │  FeedSchedule  │                                                  │
│  │    @Model      │                                                  │
│  ├────────────────┤                                                  │
│  │ id: UUID       │                                                  │
│  │ amGrain: String│                                                  │
│  │ pmGrain: String│                                                  │
│  │ amSupplements[]│                                                  │
│  │ amMedications[]│                                                  │
│  │ amFedToday:Bool│                                                  │
│  │ pmFedToday:Bool│                                                  │
│  │ horse: Horse?  │◀──────  (Inverse)                               │
│  └────────────────┘                                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Relationship Semantics
| Relationship | Delete Rule | Direction |
|--------------|-------------|-----------|
| Horse → HealthEvent | `.cascade` | One-to-Many |
| Horse → FeedSchedule | `.cascade` | One-to-One (optional) |
| HealthEvent → Horse | Inverse reference | Back-pointer |
| FeedSchedule → Horse | Inverse reference | Back-pointer |

---

## 6. Networking Stack

### Weather Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Location   │────▶│  Weather    │────▶│   SwiftUI   │
│  Manager    │     │  Service    │     │    View     │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │
      ▼                   ▼                   ▼
 CLLocationManager   WeatherKit.shared   @Observable
   Delegate          async/await         State Binding
```

**No REST API client** — WeatherKit is the only network dependency

---

## 7. File Structure

```
EquineLog/
├── EquineLogApp.swift              # @main entry point
├── ContentView.swift               # TabView navigation
│
├── Models/
│   ├── Horse.swift                 # @Model root entity
│   ├── HealthEvent.swift           # @Model + HealthEventType enum
│   ├── FeedSchedule.swift          # @Model feeding schedule
│   └── BlanketRecommendation.swift # Pure logic (no persistence)
│
├── ViewModels/
│   ├── FeedBoardViewModel.swift    # @Observable feed state
│   └── HealthTimelineViewModel.swift # @Observable health state
│
├── Views/
│   ├── FeedBoard/
│   │   ├── FeedBoardView.swift     # Main stable view
│   │   ├── FeedBoardRow.swift      # Horse row component
│   │   └── AddHorseView.swift      # Horse creation form
│   │
│   ├── Health/
│   │   ├── HealthTimelineView.swift # Maintenance timeline
│   │   └── AddHealthEventView.swift # Event logging form
│   │
│   ├── Weather/
│   │   └── WeatherDashboardView.swift # Blanketing assistant
│   │
│   ├── HorseProfile/
│   │   ├── HorseProfileView.swift   # Horse detail view
│   │   ├── EditFeedScheduleView.swift # Feed schedule editor
│   │   └── AnalyticsDashboardView.swift # Cost analytics
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift       # App settings
│   │   └── PaywallView.swift        # Subscription gate
│   │
│   └── Components/
│       └── (empty - components inline)
│
├── Services/
│   ├── WeatherService.swift        # WeatherKit + LocationManager
│   └── PDFReportService.swift      # PDF generation
│
├── Theme/
│   └── EquineTheme.swift           # Colors, fonts, modifiers
│
├── Utilities/
│   └── SharedUtilities.swift       # FeedSlot, HapticManager, etc.
│
└── Preview/
    └── PreviewContainer.swift      # In-memory SwiftData for previews
```

---

## 8. State Management Summary

| State Type | Scope | SwiftUI Property Wrapper |
|------------|-------|--------------------------|
| View-local UI state | Single view | `@State` |
| ViewModel state | View + children | `@State` + `@Observable` |
| Persisted data | App-wide | `@Query` (SwiftData) |
| Model editing | Detail views | `@Bindable` (SwiftData) |
| Environment values | Injected context | `@Environment` |
| User defaults | App preferences | `@AppStorage` |

---

## 9. Build Configuration

| Setting | Value |
|---------|-------|
| Minimum iOS Version | 17.0 |
| Swift Version | 6.0 |
| Required Capabilities | WeatherKit, Location |
| Entitlements Needed | `com.apple.developer.weatherkit` |
