# NewsApto — Intelligent News Reader

<p align="center">
  <img src="NewsApto/Assets.xcassets/AppIcon.appiconset/icon.png" width="120" alt="NewsApto">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26+-007AFF?style=flat-square&logo=apple&logoColor=white" alt="iOS 26+">
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-Native-00C7BE?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Dependencies-Zero-34C759?style=flat-square" alt="Zero Dependencies">
  <img src="https://img.shields.io/badge/Architecture-Clean-8E8E93?style=flat-square" alt="Clean Architecture">
  <img src="https://img.shields.io/badge/Localization-EN%20%2F%20TR-red?style=flat-square" alt="Localization">
</p>

NewsApto aggregates live content from six world-class sources — NewsAPI, The Guardian, The New York Times, GNews, NewsData.io, and HackerNews — then scores, categorizes, deduplicates, and ranks every article using a custom scoring algorithm. The result is a single, intelligent feed that surfaces the most relevant stories first.

No ads. No tracking. No third-party SDKs.

---

## Architecture

```
NewsApto/
├── App/                    # App entry, lifecycle, dependency injection
├── Core/                   # Shared infrastructure
│   ├── DesignSystem/       # Theme, colors, typography, reusable components
│   ├── Extensions/         # Foundation extensions
│   ├── Localization/       # L10n system (EN + TR)
│   ├── Logging/            # Structured logger
│   ├── Network/            # HTTP client, retry, monitoring
│   └── Storage/            # Core Data models, repositories
├── Features/
│   ├── ArticleDetail/      # Article reading view
│   ├── Bookmark/           # Reading list management
│   ├── Onboarding/         # First-run experience
│   ├── ReadingList/        # Saved articles
│   ├── Search/             # Article search
│   └── Sources/            # Article feed, scoring, aggregation
├── NewsAptoTests/          # Unit tests
└── NewsAptoUITests/        # UI tests
```

### Key Design Decisions

| Principle | Implementation |
|-----------|---------------|
| **Clean Architecture** | `Sources` owns domain logic, `Core` provides infrastructure, `Features` own presentation |
| **Smart Scoring** | Multi-factor article scoring: recency, source authority, topic diversity, user engagement |
| **Multi-source Aggregation** | 6 API sources with unified model; each client is an isolated adapter |
| **Zero External Dependencies** | URLSession, Core Data, SwiftUI only — no CocoaPods, SPM, or third-party SDKs |
| **Protocol-driven Networking** | Every API client conforms to a `NewsAPIClient` protocol for testability |
| **Actor-based Concurrency** | Thread-safe sources with Swift actors + async/await |
| **Retry + Resilience** | Exponential backoff, network monitoring, graceful degradation |

---

## Features

### Intelligent Feed
- Six-source aggregation with automatic deduplication
- SmartArticleScorer: recency, authority, topic diversity, user reading patterns
- Topic categorization and diversity engine
- Pull-to-refresh with incremental loading

### Search
- Full-text search across aggregated articles
- Filter by source, category, date range
- Recent search history

### Reading List
- Save articles for later with Core Data persistence
- Bookmark management
- Offline access to saved content

### Article Detail
- Rich article view with inline images
- Source attribution and external links
- Share support

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI** | SwiftUI |
| **Concurrency** | Swift actors + async/await |
| **Networking** | URLSession with retry + exponential backoff |
| **Persistence** | Core Data + Keychain |
| **Dependencies** | Zero (Apple SDKs only) |

---

## Installation

### Requirements
- Xcode 16+
- iOS 26+
- API keys for desired news sources

### Setup

```bash
git clone https://github.com/bilgenworks/NewsApto.git
cd NewsApto
cp .env.example .env
```

Edit `.env` to add your API keys and run the setup script:

```bash
make setup
open NewsApto.xcodeproj
```

Select the **NewsApto** scheme, build and run.

---

## Project Statistics

| Metric | Value |
|--------|-------|
| Swift files | ~84 (production) |
| External dependencies | Zero |
| API sources | 6 |
| Minimum deployment | iOS 26 |
| Localized languages | 2 (EN, TR) |

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built with SwiftUI + first-party Apple SDKs by <a href="https://github.com/bilgenworks">Bilgen Works</a></sub>
</p>
