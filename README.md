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
- **Image Caching** — Two-tier cache: in-memory NSCache (cost-based, 50MB) + disk cache (200MB, 7-day TTL)
- **Disk Caching** — Page 1 of articles and the sources list are cached to disk with TTL (60s/300s)
- **Retry Policy** — Exponential backoff with jitter for transient network failures
- **Offline Mode** — Real-time connectivity monitoring with offline banner and graceful degradation
- **Localization** — Full Turkish (TR) and English (EN) support with in-app language switching
- **Theming** — Three theme modes: Light, Dark, System

### Apple Ecosystem
- **Home Screen & Lock Screen Widget** — Top headlines refreshed every 15 minutes
- **Share Extension** — Save articles directly from Safari and other apps
- **Core Spotlight** — Search articles from iOS system search
- **Background App Refresh** — Periodic background updates for fresh content
- **State Restoration** — Returns to the last viewed screen across app launches

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
- **Persistence:** `FilePersistentStore` (disk JSON cache) + `Core Data` (reading list) + `UserDefaults` (settings)
- **Testing:** XCTest (unit + UI tests)
- **Build Tool:** Xcode 15+
- **Automation:** Makefile (`make test`, `make lint`, `make build`)

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
│   ├── BackgroundRefreshManager.swift       # BGAppRefreshTask handler
│   ├── StateRestorationManager.swift        # NSUserActivity restoration
│   └── NewsFlowApp.swift                    # @main entry point
├── Core/
│   ├── DesignSystem/                        # Colors, Spacing, Modifiers, Shimmer
│   ├── Localization/                        # L10n helper + LanguageManager
│   ├── Networking/                          # NewsAPI client, retry policy, image cache
│   ├── Persistence/                         # File & in-memory stores, Core Data model
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
├── Domain/UseCases/
│   ├── IndexArticlesInSpotlightUseCase.swift # Core Spotlight indexing
│   └── ...                                  # Fetch, Filter, Manage use cases
├── NewsFlowWidget/                          # WidgetKit extension (manual target setup)
│   ├── NewsFlowWidget.swift
│   ├── Provider.swift
│   └── EntryView.swift
├── NewsFlowShareExtension/                  # Share extension (manual target setup)
│   └── ShareViewController.swift
├── ADR/                                     # Architecture Decision Records
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

### 2. Configure Secrets

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# Edit Config/Secrets.xcconfig and add your NewsAPI.org key
```

> The app uses [NewsAPI.org](https://newsapi.org) for live data. The API key is injected via `Config/Secrets.xcconfig`, which is gitignored and never committed.
>
> For previews and UI testing, the app includes bundled mock data and does not require a valid API key.

### 3. Open in Xcode

```bash
open NewsFlow.xcodeproj
```

### 4. Build & Run

Select the `NewsFlow` scheme and run on iPhone 15+ Simulator (or any iOS 15+ device).

### Makefile Commands

```bash
make setup    # Install SwiftLint
make lint     # Run SwiftLint
make lint-fix # Auto-fix SwiftLint violations
make test     # Run unit tests
make build    # Build the project
make clean    # Clean build artifacts
make pre-commit # Run lint + tests before committing
```

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

Architecture Decision Records (ADRs) documenting major design choices are available in the [`ADR/`](ADR/) directory.

### Prefetching Implementation

Before the user reaches the last 3 articles, `ArticlesViewModel.prefetchNextPageIfNeeded()` is triggered via `.onAppear` on `ArticleCardView`. This loads the next page in the background without changing the UI state (`isPrefetching` flag prevents duplicate requests).

### Image Caching Strategy

`ImageCache` is a professional two-tier cache:
- **Memory tier**: `NSCache` with cost-based eviction (50MB limit) and LRU tracking
- **Disk tier**: File-based cache in the Caches directory (200MB limit, 7-day TTL) with automatic cleanup
- Images are downsampled to target size before storage to reduce memory footprint

### Retry Policy

Network requests use exponential backoff with jitter via `RetryingNewsAPIClientDecorator`. It retries on network errors and 5xx server errors, but not on client errors (4xx) or cancellation.

### Error Simulation (Debug Only)

`EveryThirdRequestErrorSimulator` is wrapped in `#if DEBUG` and only injected in debug/UITest builds. It deterministically fails every 3rd non-automatic request, allowing reliable testing of retry flows and error UI without relying on flaky network conditions.

### Localization Performance

`L10n.text()` caches the resolved `Bundle` to avoid repeated `UserDefaults` lookups and file system access on every localized string fetch. The cache is invalidated when `LanguageManager.setLanguage()` is called.

### Core Data Migration

The reading list migrated from `UserDefaults` to Core Data for proper relational persistence, indexing, and migration support. See [`ADR/004-core-data-for-reading-list.md`](ADR/004-core-data-for-reading-list.md).

---

## Widget & Extensions Setup

The project includes source code for Widget and Share Extension, but you must manually add the targets in Xcode:

### Widget Extension
1. File → New → Target → Widget Extension → Name it `NewsFlowWidget`
2. Add files from `NewsFlowWidget/` to the new target
3. Add `NewsAPIKey` to the Widget's `Info.plist` (or share via App Group)
4. Build and add the widget to your Home Screen

### Share Extension
1. File → New → Target → Share Extension → Name it `NewsFlowShareExtension`
2. Add files from `NewsFlowShareExtension/` to the new target
3. Enable App Groups (`group.burakbilgen.NewsFlow`) for both main app and extension
4. Add `newsflow` URL scheme to main app Info.plist for deep linking

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
