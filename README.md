# NewsFlow

A production-ready iOS news reader built with **Clean Architecture**, **MVVM**, and **zero third-party dependencies** — demonstrating senior-level patterns used in Apple-focused apps at scale.

<p align="center">
  <img src="https://img.shields.io/badge/iOS-15.0+-blue" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-3.0-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/100%25%20Native-OK-green" alt="Zero Dependencies">
</p>

---

## Why This Project?

This isn't another "follow a tutorial" app. It's a **production-grade codebase** that demonstrates the architecture, patterns, and techniques you'd use building apps for **millions of users**.

**What you'll find:**

- **Zero external dependencies** — Native `URLSession`, no Alamofire/RxSwift/Combine clutter
- **Actor-isolated concurrency** — Thread-safe caches without locks or race conditions
- **Decorator-pattern networking** — Retry, error simulation, auth — transparently layered
- **Two-tier caching** — Memory (50MB NSCache) + Disk (200MB, 7-day TTL)
- **Offline-first architecture** — Disk persistence with graceful degradation
- **Full Apple integration** — Spotlight indexing, Background Refresh, State Restoration

**TL;DR:** If you want to show recruiters you can build apps the "right way" — this is the code to reference.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Presentation Layer                 │
│         SwiftUI Views + @MainActor ViewModels         │
├─────────────────────────────────────────────────────────────┤
│                    Domain Layer                  │
│        Use Cases, Protocols, Entities          │
├─────────────────────────────────────────────────────────────┤
│                     Data Layer                 │
│   Repositories (Remote + Cache), NetworkClient   │
└─────────────────────────────────────────────────────────────┘
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

- **`actor`** — Thread-safe caches and persistence without locks
- **`async/await`** — All network/persistence ops are asynchronous
- **Generic DTOs** — `凤凰<T>` decoder works with any Codable type
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
| **CI/CD** | Makefile (`make test`, `make lint`) |

---

## Project Structure

```
NewsFlow/
├── App/                          # @main, DI, navigation
│   ├── AppContainer.swift          # Composition root (Factory pattern)
│   ├── NewsFlowApp.swift         # Entry point
│   └── RootNavigationView.swift    # Type-safe navigation
├── Domain/                       # Business logic
│   ├── Models/                  # Article, Source, etc.
│   ├── Protocols/               # Repository interfaces
│   └── UseCases/               # FetchArticles, ToggleReadingList
├── Data/                       # Data access
│   ├── Network/                # NewsAPIClient, DTOs, decorators
│   ├── Persistence/           # Core Data, FilePersistentStore
│   └── Repositories/          # Remote + cache layers
├── Infrastructure/             # Cross-cutting
│   ├── DesignSystem/          # Colors, spacing, components
│   ├── Networking/           # Retry policy, logging
│   ├── L10n/               # Localization
│   └── PreviewSupport/        # Mock data for previews
└── Presentation/              # UI
    ├── Sources/              # Sources list screen
    ├── Articles/            # Articles feed screen
    ├── Settings/            # Settings screen
    └── ...other screens
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

### API Key

The app uses [NewsAPI.org](https://newsapi.org) for live news. Create `Config/Secrets.xcconfig`:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Add your API key to the file. **Not required for previews** — mock data is bundled.

### Commands

```bash
make test     # Run unit tests
make lint    # Run SwiftLint
make build   # Build project
```

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
xcodebuild test -scheme NewsFlow -destination 'platform=iOS Simulator,name=iPhone 17e'
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
| **Adapter** | `ImageCacheAdapter` | `ImageCacheAdapter.swift` |
| **Facade** | `NewsAPIClientProtocol` | `NewsAPIClient.swift` |
| **Builder** | Request builder | `NewsAPIEndpoint.swift` |
| **Paginator** | Smart pagination | `Paginator.swift` |
| **Property Wrapper** | `@UserDefault` | `UserDefaultWrapper.swift` |
| **Service Locator** | `AppContainer.shared` | `AppContainer.swift` |

---

## Why Zero Dependencies?

1. **`URLSession` + `async/await`** — Already complete. Alamofire adds nothing.
2. **Image Caching** — Custom implementation gives full control over memory pressure
3. **Smaller Binary** — No SPM packages, ultra-fast builds
4. **No CI Headaches** — No macro trust prompts, no broken plugins
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

---

<p align="center">
  Built with SwiftUI
</p>