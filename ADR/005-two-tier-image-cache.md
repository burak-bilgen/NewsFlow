# ADR 005: Two-Tier Image Cache

## Status
Accepted

## Context
News articles contain images that are repeatedly loaded while scrolling. We needed a caching strategy that:
- Avoids re-downloading images during scrolling
- Survives app restarts
- Respects memory pressure
- Supports downsampling for different cell sizes

## Decision
We built a custom `ImageCache` actor with two tiers:

1. **Memory Tier**: `NSCache<NSString, MemoryCacheEntry>`
   - Cost-based eviction (50MB limit)
   - LRU tracking via `lastAccessed` timestamp
   - Concurrent-safe via actor isolation

2. **Disk Tier**: `FileManager`-backed storage in Caches directory
   - 200MB limit
   - 7-day TTL with periodic cleanup
   - Metadata JSON for access tracking

## Consequences

### Positive
- Full control over cache behavior
- No third-party image library needed
- Supports preloading and downsampling
- Memory pressure automatically handled by NSCache

### Negative
- Must manually implement cleanup and eviction
- No built-in animated image support (GIF, WebP)

## Future Work
- Add support for WebP decoding
- Implement cache warming on app launch
- Add metrics for hit/miss ratios
