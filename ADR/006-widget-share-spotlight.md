# ADR 006: Widget, Share Extension, and Spotlight

## Status
Accepted

## Context
To demonstrate deep integration with the Apple ecosystem and provide value outside the app, we decided to add:
- Home Screen & Lock Screen Widgets
- Share Extension for Safari
- Core Spotlight indexing

## Decision

### Widget (`NewsFlowWidget`)
- `StaticConfiguration` with `TimelineProvider`
- Refreshes every 15 minutes
- Supports `.systemSmall`, `.systemMedium`, `.systemLarge`, and Lock Screen accessory families
- Fetches data independently via `URLSession` (since Widget target cannot import main app module without framework extraction)

### Share Extension (`NewsFlowShareExtension`)
- `SLComposeServiceViewController` subclass
- Extracts URL from share sheet
- Stores in shared `UserDefaults` (with App Group) for main app pickup
- Deep link support via `newsflow://` URL scheme

### Core Spotlight (`IndexArticlesInSpotlightUseCase`)
- Indexes article titles and source names
- Supports system-wide search
- Provides deep links back to article detail

## Consequences

### Positive
- Demonstrates Apple ecosystem expertise (common senior interview topic)
- Increases app discoverability and engagement
- Shows understanding of App Extensions lifecycle and constraints

### Negative
- Widget cannot easily share Core Data container without App Groups
- Share Extension requires manual Info.plist and entitlements setup
- Additional target complexity in Xcode project

## Setup Notes
These features require manual Xcode target creation:
1. File → New → Target → Widget Extension
2. File → New → Target → Share Extension
3. Configure App Groups and entitlements
4. Add `NewsFlowWidget/` and `NewsFlowShareExtension/` files to respective targets
