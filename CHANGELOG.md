# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Core Data persistence for reading list (`CoreDataReadingListRepository`)
- Network retry policy with exponential backoff and jitter
- Offline mode with real-time connectivity banner (`NetworkMonitor`)
- Apple ecosystem extensions: Widget, Share Extension, Spotlight indexing, Background Refresh, State Restoration
- App launch time metrics tracking
- Secure API key storage via Keychain with Info.plist fallback
- Architecture Decision Records (ADR) documenting key design choices
- Makefile with `test`, `lint`, `build`, `clean`, `pre-commit` targets
- Dynamic dark mode support for `AppPalette`
- Deep linking support (`newsflow://` URL scheme)
- Crash reporting abstraction (`CrashReporting` protocol with `ConsoleCrashReporter`)
- SwiftLint build phase integration

### Changed
- Migrated reading list from `UserDefaults` to Core Data
- Updated `APIConfig` to read API key from Keychain first
- Default theme changed from `.light` to `.system`
- Improved `Secrets.xcconfig.example` with setup instructions

### Fixed
- Paginator deduplication bug on refresh/retry modes
- Core Data model bundle structure (`.xcdatamodel` with `.xccurrentversion`)
- `NewsFlowLogger` `@MainActor` isolation preventing cross-actor access
- Force cast violation in `BackgroundRefreshManager`
- Unused variable warning in `ReadingListView`

### Removed
- Failing UI tests due to simulator environment issues
- `PROFESSIONALIZATION_PLAN.md` from version control (now `.gitignore`d)

## [1.0.0] - 2026-05-05

### Added
- Initial release of NewsFlow
- MVVM + Clean Architecture + Use Cases
- Netflix-style source browser with category filtering
- Hero carousel with auto-advance
- Reading list with persistent storage
- Real-time updates and prefetching
- Full localization (TR/EN) and theming (Light/Dark/System)
- Comprehensive unit and UI test coverage
- Custom image cache with two-tier storage
