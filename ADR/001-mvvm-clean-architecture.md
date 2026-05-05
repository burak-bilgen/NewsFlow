# ADR 001: MVVM + Clean Architecture + Use Cases

## Status
Accepted

## Context
NewsFlow is a professional news reader app targeting iOS 15+. We needed an architecture that:
- Scales as features grow (Sources, Articles, Reading List, Settings)
- Enables comprehensive unit testing without UI dependencies
- Keeps UI logic (SwiftUI) separate from business rules
- Supports async/await concurrency from day one

## Decision
We adopted a layered architecture:

```
Presentation (SwiftUI Views + ViewModels)
    ↓
Domain (Use Cases + Entities + Repository Protocols)
    ↓
Data (Repository Implementations + Network + Persistence)
```

- **MVVM**: One `@MainActor` ViewModel per screen with `@Published` state
- **Repository Pattern**: Protocol-driven data access, allowing remote + local cache layers
- **Use Cases**: Encapsulate single business operations (e.g., `FetchArticlesUseCase`, `FilterSourcesUseCase`)
- **Dependency Injection**: `AppContainer` acts as the composition root, wiring all dependencies via constructor injection

## Consequences

### Positive
- ViewModels are fully unit-testable with mock repositories
- Business logic is reusable across features
- Easy to swap implementations (e.g., `UserDefaultsReadingListRepository` → `CoreDataReadingListRepository`)

### Negative
- More boilerplate than simple MVVM (protocols, factories, DTOs)
- Slightly steeper onboarding for new developers

## Alternatives Considered
- **MVP**: Too much manual view updating for SwiftUI
- **VIPER**: Overkill for a single-developer project; too many files
- **TCA (The Composable Architecture)**: Third-party dependency; we wanted zero external dependencies
