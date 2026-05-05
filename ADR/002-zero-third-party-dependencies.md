# ADR 002: Zero Third-Party Dependencies

## Status
Accepted

## Context
Many iOS projects immediately pull in Alamofire, Kingfisher, SnapKit, and RxSwift. We wanted to demonstrate deep knowledge of Apple's frameworks and keep the binary size minimal.

## Decision
We use only Apple's first-party frameworks:
- `URLSession` + `async/await` for networking
- `NSCache` + custom disk cache for images
- `SwiftUI` + `Combine` (minimal) for UI
- `XCTest` for testing
- `Core Data` for persistence (added later)
- `WidgetKit` for widgets

## Consequences

### Positive
- Full control over memory pressure handling (custom image cache)
- No dependency update churn or breaking changes
- Smaller binary size and faster build times
- Demonstrates mastery of foundational Apple APIs

### Negative
- Must implement features that libraries provide out-of-the-box (image loading, retry logic)
- More code to maintain for cross-cutting concerns

## Exceptions
- Snapshot testing libraries may be added later for UI regression testing, gated behind `#if DEBUG`
