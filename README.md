# EquineLog

A high-end barn management app built with SwiftUI and SwiftData.

## Tech Stack

- **Language:** Swift 6 / SwiftUI
- **Persistence:** SwiftData (local-first)
- **Weather:** WeatherKit
- **PDF Generation:** PDFKit
- **Architecture:** MVVM with `@Observable`

## Features

### Core 1: Digital Feed Board
High-contrast list view of all horses with AM/PM feed details, supplements, medications, and "Mark as Fed" toggle. Includes search and filter by fed status.

### Core 2: Health Timeline
Maintenance tab listing upcoming Farrier (6-8 week cycle), Vet, Deworming, and Dental events. Overdue items highlighted in red. Filter by event type.

### Core 3: Blanketing Assistant
Weather dashboard using WeatherKit for current conditions. Provides per-horse blanket recommendations based on temperature and clipped/unclipped status.

### Core 4: Owner Reports & Analytics
- PDF generation of 30-day health summaries via PDFKit
- Analytics dashboard with cost trends, category breakdowns, cycle compliance tracking, projected annual costs, and actionable insights

### Monetization
Free tier includes 1 horse. "Barn Mode" paywall ($19.99/mo) required for additional horses.

## Project Structure

```
EquineLog/
├── EquineLogApp.swift          # App entry point
├── ContentView.swift           # TabView navigation
├── Models/
│   ├── Horse.swift             # SwiftData horse model
│   ├── HealthEvent.swift       # Health event model + types
│   ├── FeedSchedule.swift      # AM/PM feed schedule model
│   └── BlanketRecommendation.swift  # Blanket logic engine
├── ViewModels/
│   ├── FeedBoardViewModel.swift
│   └── HealthTimelineViewModel.swift
├── Views/
│   ├── FeedBoard/
│   │   ├── FeedBoardView.swift
│   │   ├── FeedBoardRow.swift
│   │   └── AddHorseView.swift
│   ├── Health/
│   │   ├── HealthTimelineView.swift
│   │   └── AddHealthEventView.swift
│   ├── Weather/
│   │   └── WeatherDashboardView.swift
│   ├── HorseProfile/
│   │   ├── HorseProfileView.swift
│   │   ├── EditFeedScheduleView.swift
│   │   └── AnalyticsDashboardView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── PaywallView.swift
├── Services/
│   ├── WeatherService.swift    # WeatherKit + LocationManager
│   └── PDFReportService.swift  # PDF generation
├── Theme/
│   └── EquineTheme.swift       # Colors, typography, components
└── Preview/
    └── PreviewContainer.swift  # In-memory SwiftData for previews
```

## Design

"Modern Equestrian" aesthetic with Hunter Green and Saddle Brown accents. Large, legible text optimized for outdoor/barn use. High-contrast feed board for dusty environments.

## Setup

1. Open in Xcode 16+
2. Set your development team for WeatherKit entitlements
3. Enable WeatherKit capability in Signing & Capabilities
4. Build and run on iOS 17+
