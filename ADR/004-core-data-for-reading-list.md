# ADR 004: Core Data for Reading List Persistence

## Status
Accepted

## Context
The reading list was initially stored in `UserDefaults` via `UserDefaultsReadingListRepository`. While functional for small datasets, this approach:
- Is semantically incorrect (UserDefaults is for preferences, not relational data)
- Does not scale well with large reading lists
- Lacks query capabilities, indexing, and migration support

## Decision
We migrated the reading list to Core Data:
- `NewsFlowModel.xcdatamodeld` with `ReadingListItem` entity
- `CoreDataReadingListRepository` implementing `ReadingListRepositoryProtocol`
- Uniqueness constraint on `id` field
- Fetch index for fast lookups
- Background context writes for UI responsiveness

## Consequences

### Positive
- Proper relational persistence with ACID guarantees
- Easy to query, sort, and filter
- Supports lightweight migration for future schema changes
- Demonstrates Core Data expertise (common interview topic)

### Negative
- More complex setup than UserDefaults
- Requires `CoreDataStack` lifecycle management
- `NSManagedObject` is reference type, requiring careful threading

## Migration Strategy
Existing users with UserDefaults data will start fresh. In a production app, we would write a one-shot migration from UserDefaults to Core Data on first launch.
