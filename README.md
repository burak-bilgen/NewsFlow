<p align="center">
  <img src="NewsApto/Assets.xcassets/AppIcon.appiconset/icon.png" width="120" alt="NewsApto Icon" />
</p>

<h1 align="center">NewsApto</h1>

<p align="center">
  <strong>The intelligent news reader that adapts to you.</strong><br/>
  Multi-source aggregation · Smart scoring · Zero dependencies · Built for iOS 26
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26+-007AFF?style=flat-square&logo=apple&logoColor=white" alt="iOS 26+">
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-Native-00C7BE?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Dependencies-Zero-34C759?style=flat-square" alt="Zero Dependencies">
  <img src="https://img.shields.io/badge/Architecture-Clean-8E8E93?style=flat-square" alt="Clean Architecture">
</p>

---

## ✨ Why NewsApto?

Most news apps are glorified RSS readers. **NewsApto** is different.

It aggregates live content from **six world-class sources** — NewsAPI, The Guardian, The New York Times, GNews, NewsData.io, and HackerNews — then scores, categorizes, deduplicates, and ranks every article using a custom **SmartArticleScorer** algorithm. The result? A single, intelligent feed that surfaces the most relevant stories first.

No ads. No tracking. No third-party SDKs. Just you and the news.

### What Makes It Special

| ✅ | Feature |
|----|---------|
| 🧠 | **Smart scoring** | Recency, content richness, source authority, and title quality determine article ranking |
| **Source authority** | Tier-based scoring (BBC/Reuters: 15pts, NYT: 14pts, HN: 11pts) |
| **Topic diversity** | NLP-based deduplication prevents feed flooding |
| 🌐 | **Multi-source aggregation** — 6 sources (NewsAPI, Guardian, NYT, GNews, NewsData, HN) in a unified feed |
| 🏷️ | **Smart categorization** — API-provided categories with 150+ mappings and keyword fallback |
| 🎭 | **Rich article detail** — Full content (2000 chars), descriptions, and immersive reading experience |
| ⚡ | **Actor-based concurrency** — Thread-safe caching and network deduplication with Swift actors |
| 🎨 | **Terminal-inspired UI** — Dark matrix aesthetic with neon accents, glitch reveals, and code rain |
| 📴 | **Offline-first** — Two-tier cache (50MB memory + 200MB disk) with seamless degradation |
| 🔁 | **Smart pagination** — Auto-prefetch, deduplication, loading guards, and pull-to-refresh |
| 🔒 | **Zero dependencies** — 100% native. No SPM. No CocoaPods. No black boxes. |

---

## 🏗️ Architecture

NewsApto follows **Clean Architecture** with strict dependency inversion:

```
┌─────────────────────────────────────┐
│          Presentation               │  SwiftUI Views + @MainActor ViewModels
│  ┌───────────┐    ┌──────────────┐  │
│  │ FeedView  │    │ HeroDetail   │  │
│  │ ReadList  │    │ Attribution  │  │
│  └─────┬─────┘    └──────┬───────┘  │
│        │                 │          │
│  ┌─────┴─────────────────┴───────┐  │
│  │         ViewModels            │  │
│  └─────────────┬─────────────────┘  │
├────────────────┼────────────────────┤
│        Domain  │                    │  Use Cases, Protocols, Entities
│  ┌─────────────┴─────────────────┐  │
│  │  ManageReadingListUseCase     │  │
│  │  ArticlesRepositoryProtocol   │  │
│  │  SmartArticleScorer           │  │
│  └─────────────┬─────────────────┘  │
├────────────────┼────────────────────┤
│          Data  │                    │  Network, Persistence, Repositories
│  ┌─────────────┴─────────────────┐  │
│  │  NewsAggregatorService        │  │
│  │  CachedArticlesRepository     │  │
│  │  CoreDataReadingListRepo      │  │
│  │  ImageCache (Actor)           │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Design Patterns Employed

| Pattern | Where | Purpose |
|---------|-------|---------|
| **MVVM** | ViewModels | `@MainActor` isolation, `@Published` state for reactive UI |
| **Repository** | Data layer | Unified interface over remote + cache layers |
| **Decorator** | `RetryingNewsAPIClientDecorator` | Transparent retry with exponential backoff |
| **Actor** | `ImageCache`, `CachedArticlesRepository`, `NewsAggregatorService` | Thread-safe concurrency without locks |
| **Factory** | `AppContainer` | Centralized dependency injection |
| **Strategy** | `SmartArticleScorer` | Pluggable scoring algorithms |
| **Property Wrapper** | `@UserDefault` | Type-safe, observable UserDefaults |

---

## 🎭 The UI

NewsApto sports a **terminal-inspired cyberpunk aesthetic** — think Bloomberg Terminal meets The Matrix:

### Animations & Effects
- **Matrix Code Rain** — Real-time Canvas rendering with 24×40 character grid, 50ms animation interval
- **Glitch Reveal** — 6-step jitter animation (30ms per step, ±3px offset) on content load
- **Matrix Emission** — Neon glow overlay with fade cycle for content transitions
- **Glow Pulse** — Infinite 1.2s ease-in-out pulse on active category buttons

### UI Components
- **Terminal search bar** — Blinking cursor, mono typography, instant filtering
- **Category ribbon** — 6 categories (Tech, Business, Science, Health, Sports, Entertainment) with glow-pulse active states
- **Magazine-style layout** — Hero card (320pt image), editor's picks grid, latest articles list
- **Hero detail view** — Full-screen with blur-to-focus image (8pt → 0pt), swipe-to-dismiss gesture
- **Status-bar-free** — Immersive reading experience

Everything is hand-built in SwiftUI. No Storyboards. No UIKit escape hatches.

---

## 📦 Tech Stack

| Layer | Technology |
|-------|------------|
| **Language** | Swift 5.9 |
| **UI Framework** | SwiftUI (iOS 26+) |
| **Networking** | `URLSession` + `async/await` |
| **Image Pipeline** | Custom `NSCache` (50MB) + Disk (200MB) with downsampling |
| **Persistence** | Core Data (reading list) + File-based disk cache + UserDefaults |
| **Concurrency** | Swift Actors + structured concurrency |
| **Logging** | Custom `NewsAptoLogger` → `os_log` unified logging |
| **Testing** | XCTest (unit + UI) |
| **Automation** | Makefile |

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 26+** with iOS 26 SDK
- iPhone Simulator or physical device

### Setup

```bash
git clone https://github.com/your-username/NewsApto.git
cd NewsApto
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Add your API keys to `Config/Secrets.xcconfig`:

```xcconfig
NEWS_API_KEY = your_newsapi_key
GUARDIAN_API_KEY = your_guardian_key
NYT_API_KEY = your_nyt_key
GNEWS_API_KEY = your_gnews_key
NEWSDATA_API_KEY = your_newsdata_key
// HackerNews: No API key needed (Free public API)
```

Open `NewsApto.xcodeproj`, select the **NewsApto** scheme, and hit ▶.

> **Note:** The app runs previews and UI tests without live API keys using built-in mock data.

### Make Commands

```bash
make build    # Build for iOS Simulator
make test     # Run unit + UI tests
make lint     # Run SwiftLint
```

Override the simulator destination if needed:

```bash
make test DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro'
```

---

## 🧪 Testing

### Unit Tests
- ViewModel state machines and transitions
- Repository cache hit/miss/expiration logic
- Network client request building and error handling
- Retry decorator with exponential backoff
- Pagination guard and prefetch logic
- Article sorting and deduplication

### UI Tests
- Full article browsing flow
- Reading list save/remove cycle
- Category filtering

```bash
make test
```

---

## 🔧 Key Engineering Decisions

### Why Zero Dependencies?

| Concern | Our Approach |
|---------|-------------|
| **HTTP** | `URLSession` + `async/await` is already complete — Alamofire adds nothing |
| **Images** | Custom cache gives full control over memory pressure and downsampling |
| **JSON** | Native `Codable` with clean DTO → domain mapping |
| **Binary size** | No SPM packages = ultra-fast builds, smaller app |
| **Trust** | No macro trust prompts, no broken plugins, no supply-chain risk |

### Why Actor-Based Concurrency?

Traditional caching with `NSLock` or `DispatchQueue` is fragile and hard to test. Swift actors give us:
- **Compile-time safety** — the compiler prevents data races
- **Structured task deduplication** — in-flight request coalescing is trivial
- **Natural async/await integration** — no callback hell

### Smart Article Scoring

Articles are ranked by a multi-factor weighted formula:

```
Score = recencyScore(40pts max) 
      + contentScore(20pts max) 
      + titleScore(10pts max)
      + sourceAuthority(15pts max)
      + trendingBonus(15pts max)
```

| Factor | Max Points | Calculation |
|--------|-----------|-------------|
| **Recency** | 40 | Exponential decay: 40pts (<1h) → 2pts (>72h) |
| **Content** | 20 | +15 image, +10 description, +5 snippet, +5 URL |
| **Title** | 10 | Length-based: 30+ chars = 10pts |
| **Source Authority** | 15 | Tier-based: BBC/Reuters (15), NYT (14), Guardian (13), HN (11) |
| **Trending** | 15 | Based on engagement velocity |

### Category System

**6 Standard Categories** with intelligent mapping:

| Category | API Sources | Keywords |
|----------|-------------|----------|
| **Technology** | GNews topic, NewsData category, HN (hardcoded) | 50+ keywords (AI, crypto, programming, etc.) |
| **Business** | Guardian section, NYT section | 50+ keywords (markets, finance, politics) |
| **Science** | All science-related APIs | 40+ keywords (space, climate, research) |
| **Health** | Guardian lifeandstyle | 30+ keywords (medical, fitness, wellness) |
| **Sports** | All sports sections | 30+ keywords (football, olympics, racing) |
| **Entertainment** | Arts & culture sections | 40+ keywords (movies, music, gaming) |

**Mapping Priority:** API-provided category → Keyword fallback → "general"

---

## 📁 Project Structure

```
NewsApto/
├── NewsApto/
│   ├── App/                          # @main entry, DI container, navigation
│   ├── Domain/
│   │   ├── Entities/                 # Article, ArticleScorer, APISource
│   │   ├── RepositoryInterfaces/     # Protocols + PaginatedResult
│   │   └── UseCases/                 # ManageReadingListUseCase
│   ├── Data/
│   │   ├── Network/                  # API clients, endpoints, DTOs, aggregator
│   │   ├── Persistence/              # Core Data, file cache, cached repositories
│   │   └── Repositories/             # NewsAPI + reading list implementations
│   ├── Core/
│   │   ├── Services/                 # EnhancedArticleScorer, TopicDiversityEngine, UserBehaviorTracker
│   │   └── Utilities/                # Logger, DateFormatter, ReadingTime
│   ├── Infrastructure/
│   │   ├── DesignSystem/             # AppPalette, AppTypography, reusable components
│   │   ├── Networking/               # ImageCache, RetryPolicy, NetworkMonitor
│   │   ├── Notifications/            # SentinelNotificationService
│   │   ├── Localization/             # en/tr string catalogs
│   │   └── PreviewSupport/           # Mock data + repositories
│   └── Presentation/
│       ├── Feed/                     # FeedView + FeedViewModel
│       ├── Articles/                 # ArticleImageView, SafariView
│       ├── ReadingList/              # ReadingListView + ViewModel
│       └── Shared/                   # HeroDetail, Search, Splash, Attribution
├── NewsAptoTests/                    # Unit tests
├── NewsAptoUITests/                  # UI tests
├── Config/                           # Secrets.xcconfig
└── Makefile
```

---

## ⚡ Performance

| Metric | Value |
|--------|-------|
| **Memory cache** | 50MB NSCache with automatic eviction |
| **Disk cache** | 200MB with 7-day TTL |
| **Image downsampling** | All images rendered at 400×400 max |
| **Content limit** | 2000 chars per article for detail view |
| **Category mappings** | 150+ API mappings, 300+ keywords |
| **Prefetch trigger** | Auto-loads next page at last 5 items |
| **Request coalescing** | Actor-based in-flight deduplication |
| **Retry** | Exponential backoff with jitter (max 3 attempts) |

---

## 🌐 Localization

NewsApto ships with **English** and **Turkish** localizations, switchable in-app.

---

## 📄 License

MIT — See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Built with ❤️ using 100% native Apple frameworks. No third-party dependencies. Ever.</sub>
</p>
