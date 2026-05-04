# NewsFlow

NewsFlow is a SwiftUI iOS app for browsing news sources and articles through the NewsAPI v2 endpoints. It supports English source filtering, multi-category filtering, article carousels, and local reading list persistence.

## Features

- Lists NewsAPI sources with English language filter
- Category-based source filtering (multi-select)
- Top headlines view per source with headline carousel
- Pull-to-refresh and auto-refresh (1 min)
- Reading list saved locally
- Every-third-request error simulation for testing
- Turkish UI copy for reading list and error states
- Dark mode support

## Setup

Create a config file with your NewsAPI key:

```sh
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Then edit `Config/Secrets.xcconfig`:

```xcconfig
NEWS_API_KEY = your_key_here
```

## Running

Open `NewsFlow.xcodeproj` in Xcode and run the `NewsFlow` scheme. Requires iOS 15+.

The UI test scheme runs with mocked data — no API key needed.

```sh
xcodebuild test -project NewsFlow.xcodeproj -scheme NewsFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

Feature-oriented MVVM with dependency injection via `AppContainer`. Views get view models from the container, never call networking or persistence directly.

```
NewsFlow/App          → entry point, DI container, routing
NewsFlow/Core         → networking, design system, localization, helpers
NewsFlow/Features/    → sources, articles, reading list (model + VM + view)
NewsFlowTests         → unit tests
NewsFlowUITests       → UI tests with launch arguments
```

## Known Issues

- NewsAPI image URLs vary by source, missing images show a placeholder
- No dedicated reading list screen (not required)
