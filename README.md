# NewsFlow

A production-ready iOS news application built with SwiftUI, demonstrating Clean Architecture, protocol-oriented design, comprehensive testing, and offline-first capabilities.

## Features

### Core News Experience
- Browse NewsAPI sources with English language filtering
- Multi-category source filtering with animated chip selection
- Top headlines per source with auto-advancing hero carousel
- Pull-to-refresh and 1-minute automatic background refresh
- Reading list with local persistence

### Architecture
- **Clean Architecture**: Domain, Data, and Presentation layers with clear boundaries
- **Protocol-Oriented DI**: Injectable dependencies via composition root
- **MVVM with Combine**: Reactive state management using `@Published` and `ObservableObject`
- **Router Pattern**: Programmatic navigation with `AppRouter` abstraction
- **Caching**: File-based persistent cache with TTL for offline support

### Offline First
- Sources cached for 5 minutes
- Articles cached per source for 1 minute
- Full offline reading of cached content
- Graceful degradation when network unavailable

### Design System
- Premium red/crimson primary color with gold accents
- Skeleton loading with shimmer effects
- Dynamic theming (Light / Dark / System)
- Custom haptic feedback on interactions
- Card-based layouts with shadow elevation

### Accessibility
- VoiceOver support with semantic labels
- Dynamic Type scaling
- Reduced Motion support
- High contrast compatibility
- Full RTL layout support

## Architecture

```
NewsFlow/
├── App/
│   ├── NewsFlowApp.swift          → Entry point with theme injection
│   ├── Composition/
│   │   └── AppContainer.swift     → DI container (composition root)
│   └── Routing/
│       └── RootNavigationView.swift → Router-driven navigation
├── Core/
│   ├── DesignSystem/              → Colors, spacing, typography, animations
│   ├── Localization/              → L10n helper for strings
│   ├── Networking/                → URLSession client with generics
│   ├── Persistence/               → File-based cache store
│   └── Utilities/                 → Date formatting, string helpers
├── Features/
│   ├── Sources/                   → News sources list + category filtering
│   ├── Articles/                  → Headlines carousel + article cards
│   ├── ReadingList/               → Local persistence protocol + impl
│   └── Settings/                  → Theme preferences
└── Tests/
    ├── Unit Tests/                → ViewModels, services, DTOs
    └── UI Tests/                  → End-to-end flows
```

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (iOS 15+)
- **Concurrency**: async/await with structured concurrency
- **Persistence**: File-based JSON cache + UserDefaults
- **Networking**: URLSession with generic response handling
- **Testing**: XCTest with spy doubles
- **Linting**: SwiftLint with custom rules

## Setup

1. Clone the repository
2. Copy the config file:
   ```sh
   cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
   ```
3. Add your NewsAPI key to `Config/Secrets.xcconfig`:
   ```xcconfig
   NEWS_API_KEY = your_key_here
   ```
4. Open `NewsFlow.xcodeproj` in Xcode 15+
5. Build and run the `NewsFlow` scheme

## Testing

Run unit tests:
```sh
xcodebuild test -project NewsFlow.xcodeproj -scheme NewsFlow -destination 'platform=iOS Simulator,name=iPhone 17e'
```

Run with mocked data (no API key needed):
- Select the UI test scheme or pass `UITest.MockNews` as a launch argument

## Design Decisions

### Why Protocol-Oriented DI?
Every repository, service, and utility is defined by a protocol. This enables:
- Mocking in tests without frameworks
- Swapping implementations (UserDefaults → File cache)
- Clear contracts between layers

### Why File-Based Cache?
SwiftData requires iOS 17+. To maintain iOS 15 compatibility while providing offline support, we use a custom file cache with JSON encoding and metadata timestamps.

### Why No External Dependencies?
The project uses zero third-party libraries. Every feature is built with first-party frameworks:
- URLSession for networking
- UserDefaults for light preferences
- FileManager for cache storage
- XCTest for testing

This demonstrates the ability to build robust software without relying on external packages.

## Known Limitations

- No dedicated reading list screen (not required by spec)
- NewsAPI image availability varies by source
- No background fetch / push notifications (would require server infrastructure)

## License

MIT
