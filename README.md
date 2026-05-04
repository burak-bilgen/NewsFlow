# NewsFlow

> A professional news reader app built with SwiftUI, featuring a Netflix-style source browser, auto-refreshing article feeds, and offline reading list support.

<p align="center">
  <img src="https://img.shields.io/badge/iOS-15.0%2B-blue" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-3.0-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" alt="License">
</p>

---

## Features

- **Netflix-Style Source Browser** — Browse news sources grouped by category in horizontally scrolling rows
- **Hero Carousel** — Featured articles with cinematic gradient overlays and auto-advancing pagination
- **Real-Time Updates** — Pull-to-refresh and automatic background refresh every 60 seconds
- **Reading List** — Bookmark articles for offline reading with haptic feedback
- **Error Simulation** — Every 3rd request intentionally fails to demonstrate retry flows (debug builds)
- **Dark Mode Support** — Three theme modes: Light, Dark, System
- **Accessibility First** — Full VoiceOver support, Dynamic Type, and Reduce Motion awareness

---

## Architecture

| Layer | Responsibility |
|-------|---------------|
| **Presentation** | SwiftUI Views + ViewModels (MVVM) |
| **Domain** | Models, Use Cases, Protocols |
| **Data** | Repositories, Network Layer, Persistence |

### Design Patterns
- **MVVM** — One ViewModel per screen with `@Published` state management
- **Repository Pattern** — Abstracted data sources (remote + local cache)
- **Dependency Injection** — `AppContainer` composes all dependencies
- **Protocol-Oriented** — Testable via protocol stubs (`TestDoubles.swift`)

---

## Project Structure

```
NewsFlow/
├── App/
│   ├── Composition/AppContainer.swift      # DI container
│   ├── Routing/RootNavigationView.swift    # Navigation setup
│   └── NewsFlowApp.swift                   # @main entry point
├── Core/
│   ├── DesignSystem/                       # Colors, Spacing, Modifiers
│   ├── Localization/                       # L10n helper
│   ├── Networking/                         # NewsAPI client
│   ├── Persistence/                        # File & in-memory stores
│   └── Utilities/                          # Formatters, Fixtures
├── Features/
│   ├── Articles/                           # Article list & detail
│   ├── Sources/                            # Netflix-style source browser
│   ├── Settings/                           # Theme preferences
│   └── ReadingList/                        # Bookmark persistence
└── Tests/
    ├── NewsFlowTests/                      # Unit tests (64 tests)
    └── NewsFlowUITests/                    # UI automation tests
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

### 3. Configure API Key (optional)

The app uses [NewsAPI.org](https://newsapi.org) for live data. Add your API key to `Info.plist` under the key `NewsAPIKey`, or use the bundled mock data for previews and testing.

### 4. Build & Run

Select the `NewsFlow` scheme and run on iPhone 15 Simulator (or any iOS 15+ device).

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

### Unit Tests (64 tests)

```bash
xcodebuild test -project NewsFlow.xcodeproj -scheme NewsFlow \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Coverage areas:**
- ViewModels (state transitions, error handling)
- Repositories (caching, network fallbacks)
- Networking (DTO decoding, endpoint building)
- Filtering & Sorting logic
- Persistence (reading list, UserDefaults)

### UI Tests

Automated end-to-end flows:
1. Launch app → verify sources list loads
2. Filter by category → verify rows update
3. Tap source → verify article carousel appears
4. Tap bookmark → verify saved state changes

---

## Key Technical Decisions

### Why MVVM over MVC?

MVVM separates UI logic from business logic, making ViewModels highly testable without spinning up a UI. SwiftUI's `@StateObject` and `@Published` fit naturally into this pattern.

### Why no third-party networking library?

`URLSession` + `async/await` (iOS 15+) provides everything we need. Avoiding Alamofire/AlamofireImage keeps binary size small and removes an external dependency.

### Why manual image caching?

`ImageCacheService` wraps `NSCache` with disk spillover. This gives us full control over memory pressure handling and cache eviction policies.

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
  Built with ❤️ using SwiftUI
</p>
