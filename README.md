# NewsFlow

> A professional news reader app built with SwiftUI, featuring a Netflix-style source browser, auto-refreshing article feeds, offline reading list support, and intelligent prefetching.

<p align="center">
  <img src="https://img.shields.io/badge/iOS-15.0%2B-blue" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-3.0-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" alt="License">
</p>

---

## Features

### Core Features
- **Netflix-Style Source Browser** — Browse English news sources grouped by category in horizontally scrolling rows
- **Category Multi-Selection** — Dynamically filter sources by multiple categories client-side
- **Hero Carousel** — Top 3 articles displayed in a cinematic auto-advancing carousel (5s interval)
- **Reading List** — Bookmark/unbookmark articles with persistent local storage and haptic feedback
- **Real-Time Updates** — Pull-to-refresh and automatic background refresh every 60 seconds
- **Prefetching** — Next page of articles is silently prefetched before the user reaches the end of the list

### Quality & Reliability
- **Error Simulation** — Every 3rd non-automatic request intentionally fails to demonstrate retry flows (debug builds only)
- **Image Caching** — In-memory NSCache with a count limit of 100; images do not re-download when scrolling back
- **Disk Caching** — Page 1 of articles and the sources list are cached to disk with TTL (60s/300s)
- **Localization** — Full Turkish (TR) and English (EN) support with in-app language switching
- **Theming** — Three theme modes: Light, Dark, System

### Accessibility
- Full VoiceOver support with accessibility identifiers
- Dynamic Type support
- Reduce Motion awareness for animations
- Haptic feedback for all interactive actions

---

## Architecture

NewsFlow follows **MVVM + Repository Pattern** with Clean Architecture principles.

### Layered Architecture

| Layer | Components | Responsibility |
|-------|-----------|---------------|
| **Presentation** | SwiftUI Views, ViewModels | UI rendering and user interaction state |
| **Domain** | Models, Protocols, Sorting/Filtering | Business logic and entity definitions |
| **Data** | Repositories, Network Client, Persistence | Data access, caching, and external API calls |

### Design Patterns

- **MVVM** — One `@MainActor` ViewModel per screen with `@Published` state management
- **Repository Pattern** — Protocol-driven data access with remote + local cache layers
- **Dependency Injection** — `AppContainer` composition root wires all dependencies via constructor injection
- **Protocol-Oriented Programming** — Every layer is abstracted by protocols for testability

### Concurrency
- `async/await` for all networking and persistence operations
- `@MainActor` on ViewModels to ensure UI updates happen on the main thread
- `actor` isolation for `FilePersistentStore`, `CachedRepositories`, and `UserDefaultsReadingListRepository`
- Request nonce (`latestRequestID`) prevents stale callback race conditions

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (iOS 15+)
- **Networking:** `URLSession` with `async/await` (no third-party libraries)
- **Image Caching:** Custom `NSCache`-based `ImageCacheService`
- **Persistence:** `FilePersistentStore` (disk JSON cache) + `UserDefaults` (reading list)
- **Testing:** XCTest (unit + UI tests)
- **Build Tool:** Xcode 15+

### Why No Third-Party Dependencies?
- `URLSession` + `async/await` provides everything needed for networking
- Custom image caching gives full control over memory pressure handling
- No external SPM dependencies keeps binary size small and build times fast

---

## Project Structure

```
NewsFlow/
├── App/
│   ├── Composition/AppContainer.swift       # DI composition root
│   ├── Routing/RootNavigationView.swift     # Navigation setup
│   └── NewsFlowApp.swift                    # @main entry point
├── Core/
│   ├── DesignSystem/                        # Colors, Spacing, Modifiers, Shimmer
│   ├── Localization/                        # L10n helper + LanguageManager
│   ├── Networking/                          # NewsAPI client, request builder, errors
│   ├── Persistence/                         # File & in-memory stores, cached repositories
│   ├── PreviewSupport/                      # MockRepositories, NewsFixture (DEBUG only)
│   └── Utilities/                           # Formatters, Error Simulator (DEBUG only)
├── Features/
│   ├── Articles/
│   │   ├── Models/                          # Article, ArticlesDTO
│   │   ├── Repositories/                    # ArticlesRepositoryProtocol + implementations
│   │   ├── Sorting/                         # ArticleSorting strategy
│   │   ├── ViewModels/                      # ArticlesViewModel
│   │   └── Views/                           # ArticlesView, ArticleDetailView, Components
│   ├── Sources/
│   │   ├── Models/                          # NewsSource, SourcesDTO
│   │   ├── Services/                        # SourceFilterService
│   │   ├── Repositories/                    # SourcesRepositoryProtocol + implementations
│   │   ├── ViewModels/                      # SourcesViewModel
│   │   └── Views/                           # SourcesView, Components
│   ├── Settings/
│   │   └── Views/                           # SettingsView, Components
│   └── ReadingList/
│       ├── Repositories/                    # ReadingListRepositoryProtocol + implementations
│       └── (no separate screen; toggled inline)
├── Assets.xcassets/
├── LaunchScreen.storyboard
├── Info.plist
└── Localizable.strings (en, tr)
```

---

## Requirements

- **iOS 15.0+**
- **Xcode 15+**
- **Swift 5.9+**
- **Portrait orientation only**
- **Universal app** (iPhone + iPad)

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/NewsFlow.git
cd NewsFlow
```

### 2. Open in Xcode

```bash
open NewsFlow.xcodeproj
```

### 3. Configure API Key

The app uses [NewsAPI.org](https://newsapi.org) for live data. Add your API key to the build settings or `Info.plist` under the key `NewsAPIKey`.

For previews and UI testing, the app includes bundled mock data and does not require a valid API key.

### 4. Build & Run

Select the `NewsFlow` scheme and run on iPhone 15+ Simulator (or any iOS 15+ device).

---

## Code Quality

### SwiftLint

We use [SwiftLint](https://github.com/realm/SwiftLint) to enforce style and catch common bugs.

```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint lint

# Auto-fix violations where possible
swiftlint --fix
```

> **Note:** Do **not** add SwiftLint as an SPM package or Build Tool Plugin — it can break the build due to macro trust issues on CI. Use the command-line tool or a Build Phase script instead.

### Pre-commit Checklist

- [ ] `swiftlint lint` passes with 0 violations
- [ ] All unit tests pass (`Cmd+U`)
- [ ] No `print()` statements left in production code
- [ ] No force unwraps (`!`) or implicitly unwrapped optionals
- [ ] Accessibility identifiers added to interactive elements

---

## Testing

### Unit Tests (117 tests)

```bash
xcodebuild test -project NewsFlow.xcodeproj -scheme NewsFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17e'
```

**Coverage areas:**
- **ViewModels** — State transitions, error handling, pagination, prefetch, auto-refresh, carousel clamping, stale request cancellation
- **Repositories** — Caching (hit/miss/expiration), network fallbacks, deduplication
- **Networking** — `NewsAPIClient` error mapping, `NewsAPIRequestBuilder` URL construction, DTO decoding
- **Filtering & Sorting** — English source filtering, multi-category union filtering, newest-first sorting
- **Persistence** — Reading list add/remove/toggle, `FilePersistentStore` save/load/remove, cache metadata

### UI Tests

Automated end-to-end flows:
1. Launch app → verify sources list loads
2. Tap source → verify article screen appears
3. Pull-to-refresh → verify reload completes
4. Error simulation → verify alert + retry recovers
5. Carousel auto-advance → verify page indicator updates

Run UI tests:
```bash
xcodebuild test -project NewsFlow.xcodeproj -scheme NewsFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17e' \
  -only-testing:NewsFlowUITests
```

---

## Key Technical Decisions

### Prefetching Implementation

Before the user reaches the last 3 articles, `ArticlesViewModel.prefetchNextPageIfNeeded()` is triggered via `.onAppear` on `ArticleCardView`. This loads the next page in the background without changing the UI state (`isPrefetching` flag prevents duplicate requests).

### Image Caching Strategy

`ImageCacheService` uses `NSCache<NSString, CacheEntry>` with a `countLimit` of 100. Images are loaded via `URLSession` and stored in memory. There is no disk caching for images (only for article/source JSON data), keeping the implementation simple while avoiding re-downloads during scrolling.

### Error Simulation (Debug Only)

`EveryThirdRequestErrorSimulator` is wrapped in `#if DEBUG` and only injected in debug/UITest builds. It deterministically fails every 3rd non-automatic request, allowing reliable testing of retry flows and error UI without relying on flaky network conditions.

### Localization Performance

`L10n.text()` caches the resolved `Bundle` to avoid repeated `UserDefaults` lookups and file system access on every localized string fetch. The cache is invalidated when `LanguageManager.setLanguage()` is called.

---

## Known Issues & Troubleshooting

### Build fails with "Macro must be enabled"

**Cause:** SwiftLint was accidentally added as an SPM package with macro plugins.

**Fix:**
1. Open Xcode → Project Navigator → `NewsFlow` project
2. Select **Package Dependencies** tab
3. Remove `SwiftLint` package
4. Add SwiftLint as a **Run Script** build phase instead:
   ```bash
   if which swiftlint >/dev/null; then
     swiftlint
   else
     echo "warning: SwiftLint not installed"
   fi
   ```

### "Invalid frame dimension (negative or non-finite)" runtime warning

**Cause:** Using `.frame(width: .infinity)` instead of `.frame(maxWidth: .infinity)`.

**Fix:** Always use `maxWidth:` / `maxHeight:` when passing `.infinity`.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with using SwiftUI
</p>
