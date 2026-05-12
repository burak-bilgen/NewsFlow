# NewsFlow

A production-ready iOS news reader built with **Clean Architecture**, **MVVM**, and **zero third-party dependencies** — demonstrating senior-level patterns used in Apple-focused apps at scale.

<p align="center">
  <img src="https://img.shields.io/badge/iOS-15.0+-blue" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-3.0-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/100%25%20Native-OK-green" alt="Zero Dependencies">
</p>

---

## About This Project

A production-ready iOS news reader demonstrating **Clean Architecture**, **MVVM**, and **modern Swift concurrency** — built entirely with native frameworks, zero third-party dependencies.

**Key Architectural Decisions:**

- **Actor-based concurrency** — Thread-safe caches using Swift actors, no locks or race conditions
- **Decorator pattern** — Network layer with transparent retry, error simulation, and auth decorators
- **Two-tier caching** — Memory (50MB NSCache) + Disk (200MB, 7-day TTL) with graceful fallback
- **Offline-first** — Disk persistence with seamless degradation when offline
- **Full Apple ecosystem** — Spotlight indexing, Background Refresh, State Restoration

**TL;DR:** A production-grade codebase demonstrating senior-level iOS architecture patterns in action.

---

## Architecture Overview

```
+------------------+
| Presentation     |  <-- SwiftUI + @MainActor ViewModels
+------------------+
        |
        v
+------------------+
| Domain          |  <-- Use Cases, Protocols, Entities
+------------------+
        |
        v
+------------------+
| Data            |  <-- Repositories, NetworkClient, Cache
+------------------+
```

### Core Patterns in Action

| Pattern | Where | Why |
|---------|-------|-----|
| **MVVM** | `*ViewModel.swift` | `@MainActor` isolates UI state; `@Published` drives SwiftUI |
| **Repository** | `*Repository.swift` | Remote + cache layers with transparent fallback |
| **Use Case** | `Fetch*, Toggle*UseCase` | Single-responsibility business logic |
| **Decorator** | `*Decorator.swift` | Stack retry, error simulation without touching core client |
| **Paginator** | `Paginator.swift` | Smart prefetch, deduplication, refresh-vs-append |
| **Actor Isolation** | `ImageCache`, `CachedRepositories` | Thread-safe state without locks |

### Advanced Techniques

- **`async/await`** — All network/persistence ops are asynchronous
- **`JSONDecoder`** — Type-safe DTO decoding with Codable
- **Property Wrappers** — `@UserDefault` for type-safe, observable UserDefaults
- **Keypath Navigation** — Type-safe SwiftUI `NavigationLink`
- **Value Semantics** — Immutable models with functional `copy(_:)`

---

## Key Features

### Core App
- **Source Browser** — Horizontally scrolling category rows (Business, Tech, Sports...)
- **Multi-Select Filtering** — Filter multiple categories client-side
- **Hero Carousel** — Top 3 articles, auto-advances every 5s, pauses on interaction
- **Reading List** — Inline save/remove with Core Data persistence
- **Pull-to-Refresh** + **Auto-Refresh** — 60s background timer with deduplication
- **Prefetching** — Loads next page before user reaches the end

### Quality & Reliability
- **Error Simulation** — Every 3rd request fails (decorator) — tests your error UI
- **Offline Mode** — Real-time banner, disk cache fallback
- **Memory Pressure Handling** — Proactively clears caches before OS kills app
- **Retry Policy** — Exponential backoff with jitter
- **Stale Response Prevention** — Request nonce (`latestRequestID`) discards old responses

### Apple Ecosystem
- **Spotlight Search** — Articles indexable via Core Spotlight
- **Background Refresh** — BGAppRefreshTask for fresh content
- **State Restoration** — Returns to last screen via NSUserActivity

### UX & Accessibility
- **Localization** — English + Turkish, in-app switching
- **Theming** — Light / Dark / System modes
- **VoiceOver** — Full accessibility identifiers
- **Haptics** — UIImpactFeedbackGenerator on every tap
- **Reduce Motion** — Respects user accessibility settings

---

## Tech Stack

| Component | Implementation |
|-----------|--------------|
| **Language** | Swift 5.9+ |
| **UI** | SwiftUI (iOS 15+) |
| **Networking** | `URLSession` + `async/await` |
| **Image Caching** | Custom `NSCache` (50MB) + Disk (200MB) |
| **Persistence** | Core Data (reading list) + `FilePersistentStore` (disk cache) + UserDefaults |
| **Testing** | XCTest + UITests |
| **Automation** | Makefile (`make test`, `make lint`) |

---

## Project Structure

```
NewsFlow/
 NewsFlow.xcodeproj
 ├── NewsFlow/                     # Main app target
 │   ├── App/                      # @main, DI, navigation
 │   ├── Domain/                   # Models, Protocols, Use Cases
 │   ├── Data/                    # Network, Persistence, Repositories
 │   ├── Infrastructure/          # Design system, L10n, utilities
 │   ├── Presentation/            # SwiftUI screens + ViewModels
 │   ├── Assets.xcassets/
 │   └── LaunchScreen.storyboard
 ├── Config/                       # Secrets configuration
 └── Makefile                      # Build commands
```

---

## Getting Started

### Prerequisites
- Xcode 15+
- iOS 15+ Simulator or device

### Run

```bash
git clone <this-repo>
cd NewsFlow
open NewsFlow.xcodeproj
```

Select the **NewsFlow** scheme and run on an iPhone simulator.

### API Keys

The app aggregates live news from [NewsAPI.org](https://newsapi.org), The Guardian Open Platform, and the New York Times Article Search API. Create `Config/Secrets.xcconfig`:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Add your provider keys to the file:

```xcconfig
NEWS_API_KEY = your_newsapi_key
GUARDIAN_API_KEY = your_guardian_key
NYT_API_KEY = your_nyt_key
```

The app can still run previews and UI-test mocks without live keys.

### Commands

```bash
make build    # Build project for a generic iOS Simulator target
make test     # Run unit tests on DESTINATION
make lint     # Run SwiftLint
```

If your simulator name differs, override it:

```bash
make test DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro'
```

To test the error UI in Debug builds, launch with the `Debug.SimulateNetworkErrors` argument.

---

## Testing

### Unit Tests (600+ assertions)
- ViewModel state transitions
- Repository caching (hit/miss/expiration)
- Network client + decorators
- Pagination + prefetch
- Sorting + filtering

### UI Tests
- Source selection → article screen
- Reading list toggle
- Category multi-select filtering

```bash
xcodebuild test -project NewsFlow.xcodeproj -scheme NewsFlow -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

---

## Design Patterns Table

Enterprise patterns used in real production apps:

| Pattern | Implementation | File |
|---------|----------------|------|
| **MVVM** | `@MainActor` ViewModels | `*.swift` |
| **Repository** | Remote + cache layers | `*Repository.swift` |
| **Use Case** | Business operation | `*UseCase.swift` |
| **Factory** | `AppContainer` | `AppContainer.swift` |
| **Decorator** | Stacked decorators | `*Decorator.swift` |
| **Strategy** | Sorting algorithms | `ArticleSorting.swift` |
| **Observer** | `@Published` | `*.swift` |
| **Command** | `ToastAction` | `ToastManager.swift` |
| **Adapter** | `ImageCacheAdapter` | `ImageCacheEnvironment.swift` |
| **Facade** | `NewsAPIClientProtocol` | `NewsAPIClient.swift` |
| **Builder** | Request builder | `NewsAPIEndpoint.swift` |
| **Paginator** | Smart pagination | `Paginator.swift` |
| **Property Wrapper** | `@UserDefault` | `UserDefaultWrapper.swift` |
| **Service Locator** | `AppContainer.make()` | `AppContainer.swift` |

---

## Why Zero Dependencies?

1. **`URLSession` + `async/await`** — Already complete. Alamofire adds nothing.
2. **Image Caching** — Custom implementation gives full control over memory pressure
3. **Smaller Binary** — No SPM packages, ultra-fast builds
4. **No Build Surprises** — No macro trust prompts, no broken plugins
5. **Your Code, Your Control** — No black-box dependencies hiding bugs

---

## Performance

| Metric | Value |
|--------|-------|
| **Image Memory** | 50MB NSCache + downsampling |
| **Disk Cache** | 200MB, 7-day TTL |
| **Auto-Refresh** | 60s interval |
| **Prefetch** | Triggers at last 3 items |
| **Retry** | Exponential backoff with jitter |
| **Spotlight** | Background batched indexing |

---

## License

MIT — See [LICENSE](LICENSE).
