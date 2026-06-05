# Restaurant Viewer — Design Notes

**Time budget**: 2-3 hours total (per Fini timebox)
**Platform**: iOS (you applied to Jr. iOS Developer Intern)
**Min iOS target**: iOS 16+ (justified — SwiftUI Layout protocol + AsyncImage + Charts and other modern APIs are 16+; Jr. role at a startup, no backwards-compat business case)
**Language**: Swift 5.9+
**Framework**: SwiftUI

---

## High-level Architecture

```
┌─────────────────────────────────────────────────────┐
│ RestaurantViewerApp (entry, App)                    │
└───────────────────────┬─────────────────────────────┘
                        │
              ┌─────────▼──────────┐
              │ ContentView (Root) │
              │ injects ViewModel  │
              └─────────┬──────────┘
                        │
   ┌────────────────────▼────────────────────┐
   │ RestaurantStackViewModel (@MainActor)   │
   │ - @Published cards: [Restaurant]        │
   │ - @Published topIndex: Int              │
   │ - @Published isLoading: Bool            │
   │ - @Published favorites: Set<String>     │
   │ - func loadInitial(), loadMore()        │
   │ - func showNext(), showPrevious()       │
   │ - func toggleFavorite(_:)               │
   └──┬──────────────────┬──────────────────┬┘
      │                  │                  │
      ▼                  ▼                  ▼
┌──────────┐      ┌─────────────┐    ┌──────────────┐
│ Location │      │ YelpAPI     │    │ FavoritesStore│
│ Manager  │      │ Client      │    │ (UserDefaults)│
│ async    │      │ async       │    │ Codable Set   │
└──────────┘      └─────────────┘    └──────────────┘

CardStackView → ZStack of RestaurantCard
   - cards[topIndex...topIndex+2] visible
   - card behind has slight scale + offset for depth
   - swipe-out animation via .offset + .opacity + matchedGeometryEffect

NavigationBarView
   - prev button (disabled when topIndex == 0)
   - next button (always enabled while not on last card)
   - search bar (BONUS: change query)
   - favorite count badge (BONUS)
```

---

## File / Module Layout

```
RestaurantViewer/
├── App/
│   └── RestaurantViewerApp.swift              # @main entry
├── Models/
│   ├── Restaurant.swift                       # Codable model (name, image, rating, id)
│   └── YelpSearchResponse.swift               # API response envelope
├── Services/
│   ├── YelpAPIClient.swift                    # URLSession, async/await, pagination
│   ├── LocationManager.swift                  # CLLocationManager wrapper, async coords
│   ├── FavoritesStore.swift                   # UserDefaults persistence (BONUS)
│   └── YelpConfig.swift                       # Bearer token (.gitignore'd)
├── ViewModels/
│   └── RestaurantStackViewModel.swift         # @MainActor ObservableObject
├── Views/
│   ├── ContentView.swift                      # Root, owns ViewModel
│   ├── CardStackView.swift                    # ZStack-based stack with animation
│   ├── RestaurantCard.swift                   # single card (image + name + rating + heart)
│   ├── StarRatingView.swift                   # 0-5 star renderer
│   ├── ControlBarView.swift                   # prev / next / search input
│   └── ErrorBannerView.swift                  # location denied, no internet, etc.
```

---

## Key Design Decisions (these go in the write-up)

### 1. SwiftUI vs UIKit → **SwiftUI**

- Modern (declarative, Swift-native)
- Faster to build for a 3-hour assignment
- Animation API (`.offset`, `.animation`, `matchedGeometryEffect`) is concise
- AsyncImage built-in (no need to wire image loading manually)
- **Trade-off**: less control vs UIKit; but for a card stack of 2-3 visible cards, SwiftUI handles it cleanly

### 2. MVVM with `@MainActor` ViewModel

- ViewModel owns state and exposes `@Published` for SwiftUI binding
- Networking + Location run on background, results published on MainActor
- Services are protocol-based for testability (mock Yelp + mock Location)
- **Trade-off**: skipping protocol abstraction would save 15 min; doing it because the JD says "code would be productionized"

### 3. Async/Await over Combine

- Modern Swift Concurrency, easier to read
- async APIs map naturally to "fetch next page when threshold reached"
- **Trade-off**: Combine is more powerful for reactive streams; async/await is enough for this scope

### 4. Card stack via ZStack with depth (vs UICollectionView)

- Render only top 3 cards (top + 2 behind for visual depth)
- Card behind = slight scale (0.95) + vertical offset (8) for layered look
- Dismissal: animate top card's `.offset(x: -screenWidth)` + `.opacity(0)` over 0.35s with easeOut
- Reverse animation for `previous` button
- **Trade-off**: not using UICollectionView reduces memory churn; for endless feed of cards this is fine since we only render ~3 visible

### 5. Pagination trigger

- When `topIndex >= cards.count - 3` and `!isLoading`, fire `loadMore()`
- Yelp `/businesses/search` accepts `offset` param up to 240
- Track current `offset`, increment by `limit` (50) per page
- Cap reached → silently disable further loads (Yelp API limit; document in write-up)
- **Trade-off**: 240 cap is real; production would mix in other categories / nearby locations to keep feed truly infinite

### 6. Location flow

- LocationManager wraps CLLocationManager with async API: `func currentCoordinate() async throws -> CLLocationCoordinate2D`
- Uses `CLLocationManager.requestWhenInUseAuthorization()` + delegate continuation
- Error states: denied, restricted, services off → publish to ViewModel for ErrorBannerView
- Fallback when denied: default to NYC (40.7128, -74.0060) so app still works for demo (mention in writeup as conscious choice)

### 7. Bonus features (do if time)

| Bonus | Effort | Plan |
|---|---|---|
| Landscape | 10 min | Use `GeometryReader` for card sizing; rotate-aware constraints |
| Query input | 20 min | Add `TextField` in `ControlBarView`, debounce 500ms, re-load with new `term` param |
| Favorites | 30 min | `FavoritesStore` saves `Set<String>` of Yelp IDs in UserDefaults; heart icon on card; toggle binding |

If short on time, do **favorites only** (easiest to demo, shows persistence skill).

---

## Yelp `/businesses/search` Request Shape

```
GET https://api.yelp.com/v3/businesses/search
  ?term=restaurants
  &latitude={lat}
  &longitude={lon}
  &limit=50
  &offset={offset}
  &sort_by=best_match
Authorization: Bearer {token}
```

**Response (relevant fields)**:
```json
{
  "businesses": [
    {
      "id": "abc123",
      "name": "Joe's Pizza",
      "image_url": "https://...",
      "rating": 4.5,
      "review_count": 1024,
      "location": { "address1": "...", "city": "...", "zip_code": "..." },
      "categories": [...],
      "distance": 142.5
    }
  ],
  "total": 1234
}
```

Map to `Restaurant { id, name, imageURL, rating, address, distance }`.

---

## Error Handling Strategy

| Failure mode | UX |
|---|---|
| Location denied | Fallback to NYC + small banner explaining |
| Network failure | Toast/banner with retry button |
| Yelp 401 (bad token) | Hardcoded error message (token is fixed) |
| Yelp 429 (rate limit) | Backoff + retry after 2s |
| Yelp empty results | "No restaurants found in your area" empty state |
| AsyncImage fetch fail | Placeholder image with restaurant initial |

---

## Sequence Diagram (initial load)

```
User opens app
   ↓
App starts LocationManager.currentCoordinate()
   ↓ [if granted]
ViewModel.loadInitial(lat, lon)
   ↓
YelpAPIClient.search(term: "restaurants", lat, lon, offset: 0, limit: 50)
   ↓
ViewModel publishes cards
   ↓
CardStackView renders top 3 cards
   ↓
User taps "Next"
   ↓ ViewModel.showNext()
     - topIndex += 1
     - animate top card offscreen left
   ↓
   if topIndex >= cards.count - 3 → ViewModel.loadMore()
      → YelpAPIClient.search(... offset: 50)
      → append to cards (background)
```

---

## What we ship in 3 hours

| Item | Time | In scope |
|---|---|---|
| Project setup, models, YelpAPIClient | 30 min | ✅ |
| LocationManager + permission flow | 15 min | ✅ |
| ViewModel + stack logic + pagination | 30 min | ✅ |
| Card view + animations + buttons | 45 min | ✅ |
| Error banner + empty state | 15 min | ✅ |
| Favorites (BONUS) | 30 min | ✅ if time |
| Query input (BONUS) | 20 min | maybe |
| Landscape (BONUS) | 10 min | maybe (mostly free with GeometryReader) |
| Write-up | 20 min (not in 3h budget) | ✅ |

---

## Out of scope (mention in write-up)

- Unit tests / UI tests (would need 1-2 extra hours)
- Localization / accessibility audit
- Dark/light mode polish (works by default in SwiftUI)
- Analytics / telemetry
- Caching layer for images
- True infinite feed past Yelp's 240 offset cap
- Deep linking to Yelp app on tap
- Map view alternative
