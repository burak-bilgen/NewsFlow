# NewsApto — App Store Screenshot Guide

## Required Screenshots (iPhone)

All screenshots should be 6.7" iPhone Pro Max resolution (1290×2796 px) for the App Store.
Export from Xcode Simulator → File → Save Screen Shot.

## Recommended Screenshot Order (6 screenshots)

### 1. Feed View (Hero Layout)
Simulate the main feed with hero cards, editor's picks grid, and latest articles.
- Show at least 3 hero cards with images
- Category ribbon visible at top
- Terminal style aesthetic clearly visible (dark background, green accent)
- **Caption:** "Smart news from 6 sources — scored, categorized, deduped"

### 2. Article Detail
Show the HeroDetailView with full article content.
- Image at top with the summary/content below
- Terminal-style typography
- **Caption:** "Full article summaries with rich content"

### 3. Category Filtering
Show the feed filtered by a specific category.
- Tap "Technology" or "Science" category
- Show filtered results
- **Caption:** "7 smart categories with automatic detection"

### 4. Reading List
Show saved articles in the reading list.
- At least 2-3 saved articles
- **Caption:** "Save articles to read later, even offline"

### 5. Settings
Show the settings screen.
- Cache management visible
- Notification toggle
- Version info
- **Caption:** "Full control over your news experience"

### 6. Onboarding / Search
Show either:
- The onboarding welcome screen (first launch flow), OR
- The terminal search bar with search results
- **Caption:** "Terminal search with instant filtering"

## Technical Notes

- Use iPhone 17 Pro Max simulator for highest resolution screenshots
- Enable "Debug → Optimize Interface for Rendering" for clean screenshots
- Use mock data for consistent content (not live API)
- Set the simulator to Dark Mode
- Disable the simulator's device bezel for cleaner shots (Window → Show Device Bezels → uncheck)

## App Icon

The 1024×1024 icon is already in Assets.xcassets (1024.png). Upload to App Store Connect.

## Video Preview (Optional)

A 30-second app preview video can be created using the simulator + QuickTime Player:
1. Run app in simulator
2. Open QuickTime Player → File → New Screen Recording → select simulator
3. Record ~30 seconds scrolling through feed, opening article, saving to reading list
