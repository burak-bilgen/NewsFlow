# ADR 003: Actor-Based Concurrency

## Status
Accepted

## Context
iOS 15+ supports Swift concurrency (`async/await`, `actors`). We needed to prevent data races in:
- File-based cache (`FilePersistentStore`)
- In-memory cache (`CachedRepositories`)
- Reading list operations (`UserDefaultsReadingListRepository`)

## Decision
We use `actor` isolation for all mutable shared state:
- `FilePersistentStore: PersistentStore` (actor)
- `CachedSourcesRepository` / `CachedArticlesRepository` (actor)
- `UserDefaultsReadingListRepository` (actor)
- `ImageCache` (actor)
- `CoreDataReadingListRepository` (actor)

ViewModels are `@MainActor` to ensure UI updates happen on the main thread.

## Consequences

### Positive
- Compile-time data race safety (Swift 5.5+)
- Cleaner code than manual `DispatchQueue` + locks
- Easy to reason about thread boundaries

### Negative
- Actor hopping can introduce slight overhead
- `@MainActor` on ViewModels requires careful testing with `@MainActor` test classes

## Migration Path
When moving to Swift 6 strict concurrency, we will review `@unchecked Sendable` conformances and ensure all cross-actor communication is explicit.
