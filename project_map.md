# EquineLog Project Architecture Map

*Last Updated: February 2026*

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
| Onboarding | UserDefaults-backed singleton | `OnboardingManager.shared` |

---

## 3. Module Dependency Graph

```
EquineLogApp.swift (ENTRY POINT)
        │
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          ContentView.swift                           │
│              (Onboarding Gate → TabView Navigation Hub)              │
└─────────────────────────────────────────────────────────────────────┘
        │
        ├── First Launch ───────────────────────────────┐
        │                                               ▼
        │                                    ┌───────────────────┐
        │                                    │  OnboardingView   │
        │                                    │ (5-Step Tutorial) │
        │                                    └───────────────────┘
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
│FeedTemplate   │ │ (Add/Edit)    │ │                │ │ QuickTipsView │
│  LibraryView  │ │               │ │                │ │OnboardReplay  │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘
        │                 │                 │
        └────────┬────────┴────────┬────────┘
                 ▼                 ▼
        ┌───────────────┐ ┌───────────────┐
        │HorseProfileView│ │   Services    │
        │EditFeedSchedule│ │WeatherService │
        │AnalyticsDash   │ │PDFReportService│
        └───────────────┘ │LocationManager │
                          └───────────────┘
                 │
                 ▼
        ┌───────────────────────────────────────┐
        │           SwiftData Models            │
        │   Horse ◀──▶ HealthEvent             │
        │     │                                 │
        │     ▼                                 │
        │   FeedSchedule    FeedTemplate        │
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
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainerFactory.createProductionContainer()
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### App Lifecycle
1. `@main` attribute designates entry point
2. `ModelContainerFactory` creates container with migration support
3. `WindowGroup` creates the root window
4. `.modelContainer()` injects SwiftData persistence
5. `ContentView` checks onboarding state → shows `OnboardingView` or `TabView`

---

## 5. Persistence Layer

### SwiftData Schema (Version 1.0.0)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ModelContainer                               │
│           (VersionedSchema + SchemaMigrationPlan)                    │
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
│  ┌────────────────┐       ┌────────────────┐                        │
│  │  FeedSchedule  │       │  FeedTemplate  │  (Standalone)          │
│  │    @Model      │       │    @Model      │                        │
│  ├────────────────┤       ├────────────────┤                        │
│  │ id: UUID       │       │ id: UUID       │                        │
│  │ amGrain: String│       │ name: String   │                        │
│  │ pmGrain: String│       │ description    │                        │
│  │ amSupplements[]│       │ amGrain, pmGrain│                       │
│  │ amMedications[]│       │ supplements    │                        │
│  │ amFedToday:Bool│       │ usageCount: Int│                        │
│  │ pmFedToday:Bool│       │ createdAt: Date│                        │
│  │ horse: Horse?  │       └────────────────┘                        │
│  └────────────────┘                                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Schema Migration Strategy

```swift
enum EquineLogMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]  // Future: SchemaV2.self, etc.
    }
    static var stages: [MigrationStage] { [] }  // Lightweight by default
}
```

### Relationship Semantics
| Relationship | Delete Rule | Direction |
|--------------|-------------|-----------|
| Horse → HealthEvent | `.cascade` | One-to-Many |
| Horse → FeedSchedule | `.cascade` | One-to-One (optional) |
| HealthEvent → Horse | Inverse reference | Back-pointer |
| FeedSchedule → Horse | Inverse reference | Back-pointer |
| FeedTemplate | Standalone | No relationships |

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
 @MainActor Singleton  15-min Cache     State Binding
 Thread-Safe Delegate  Rate Limited
```

**No REST API client** — WeatherKit is the only network dependency

### Thread Safety Model
- `WeatherService`: `@MainActor` isolated
- `LocationManager`: `@MainActor` singleton with `nonisolated` delegate methods
- Delegate callbacks dispatch to MainActor via `Task { @MainActor in ... }`

---

## 7. File Structure

```
EquineLog/
├── EquineLogApp.swift              # @main entry point
├── ContentView.swift               # Onboarding gate + TabView navigation
│
├── Models/
│   ├── Horse.swift                 # @Model root entity
│   ├── HealthEvent.swift           # @Model + HealthEventType enum
│   ├── FeedSchedule.swift          # @Model feeding schedule
│   ├── FeedTemplate.swift          # @Model reusable feed templates
│   └── BlanketRecommendation.swift # Pure logic (no persistence)
│
├── ViewModels/
│   ├── FeedBoardViewModel.swift    # @Observable feed state + undo
│   └── HealthTimelineViewModel.swift # @Observable health state + filters
│
├── Views/
│   ├── FeedBoard/
│   │   ├── FeedBoardView.swift     # Main stable view
│   │   ├── FeedBoardRow.swift      # Horse row component
│   │   ├── AddHorseView.swift      # Horse creation form
│   │   └── FeedTemplateLibraryView.swift # Template management
│   │
│   ├── Health/
│   │   ├── HealthTimelineView.swift # Maintenance timeline
│   │   └── AddHealthEventView.swift # Event add/edit form
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
│   │   ├── SettingsView.swift       # App settings + replay tutorial
│   │   ├── PaywallView.swift        # Subscription gate
│   │   ├── QuickTipsView.swift      # Feature tips
│   │   └── OnboardingReplayView.swift # Tutorial replay
│   │
│   └── Components/
│       └── (empty - components inline)
│
├── Onboarding/
│   ├── OnboardingManager.swift     # UserDefaults-backed state
│   └── OnboardingView.swift        # 5-step tutorial flow
│
├── Services/
│   ├── WeatherService.swift        # WeatherKit + LocationManager (MainActor)
│   └── PDFReportService.swift      # PDF generation
│
├── Schema/
│   └── SchemaVersions.swift        # VersionedSchema + MigrationPlan
│
├── Theme/
│   └── EquineTheme.swift           # Colors, fonts, modifiers, Toast
│
├── Utilities/
│   └── SharedUtilities.swift       # FeedSlot, HapticManager, Validation
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
| Onboarding state | App-wide singleton | `OnboardingManager.shared` |

---

## 9. Feature Summary (MVP + Tier 1/2)

### Core Features
- **Feed Board**: AM/PM feeding tracker with toggle, mark all, undo
- **Health Timeline**: Event tracking with filters by type and horse
- **Weather Dashboard**: Blanket recommendations via WeatherKit
- **Horse Profiles**: Detail view with analytics and PDF reports

### Premium Features (Tier 1 - Friction Reduction)
- Real-time form validation with animated indicators
- Toast notifications on save actions
- Undo banner for feed toggles (4-second window)
- "Mark All Fed" bulk action
- Loading states on save buttons

### Premium Features (Tier 2)
- Horse-specific health filter (filter events by horse)
- Feed template library (save, apply, reuse schedules)
- Edit existing health events (tap to edit)
- Interactive onboarding tutorial (5 steps)
- Quick Tips guide in Settings

---

## 10. Build Configuration

| Setting | Value |
|---------|-------|
| Minimum iOS Version | 17.0 |
| Swift Version | 6.0 |
| Required Capabilities | WeatherKit, Location |
| Entitlements Needed | `com.apple.developer.weatherkit` |
| Architecture | arm64 (Apple Silicon + A-series) |

---

## 11. Testing Infrastructure

| Test Suite | Framework | Coverage |
|------------|-----------|----------|
| Unit Tests | Swift Testing | FormValidation, BlanketRecommendation |
| Integration | Swift Testing | LocationManager, WeatherService |
| Utility Tests | Swift Testing | FeedSlot, StringUtilities, Calendar |

**Test File:** `EquineLogTests/LocationManagerTests.swift`
