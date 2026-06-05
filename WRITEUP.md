# Restaurant Viewer — Write-Up

> Per Fini's assignment, this write-up addresses three questions. Time spent on this write-up is not counted against the 3-hour budget.

---

## 1. How long did you spend working on the problem? What did you find to be the most difficult part?

**Total coding time**: ~2.5 hours.

Rough breakdown:

| Phase | Time |
|---|---|
| Read assignment, sketch architecture, decide on SwiftUI + MVVM + async/await | 15 min |
| Project skeleton, `YelpConfig`, models, wire-format mapping | 20 min |
| `LocationManager` (async wrapper around `CLLocationManager`) | 20 min |
| `YelpAPIClient` (URLSession, error mapping, pagination math) | 25 min |
| `RestaurantStackViewModel` (state, prefetch trigger, search reset, favorites) | 30 min |
| Card view, stack layering, animation, control bar | 40 min |
| Error banner, empty state, polish | 15 min |

**Most difficult part**: the **card-stack animation**. Conceptually simple — top card slides left, next card scales up into place — but getting the `zIndex` math, the `transition`, and the `.animation(_:value:)` triggers to cooperate without flickering took the longest. I landed on rendering `topIndex...topIndex+2` and animating the index change, which keeps SwiftUI's diffing predictable.

Runner-up: the **continuation pattern for `CLLocationManager`**. Bridging the delegate-callback world into an async API while handling the "authorization not yet determined → prompt → first fix" flow needs care so the continuation is resumed exactly once.

---

## 2. What trade-offs did you make? What did you choose to spend time on, and what did you choose to ignore or do quickly for the sake of completing the project?

### Spent meaningful time on

- **Service abstraction.** `YelpAPIClient` and `FavoritesStoring` are protocols, not concrete types. This is mild over-engineering for a 3-hour take-home, but the JD called out "code as though it would be productionized," and it costs only a few minutes to swap a protocol header in.
- **Pagination edge cases.** Yelp's `/businesses/search` caps `offset + limit ≤ 240`. The view model tracks `didReachEndOfYelp` and silently stops paging, rather than crashing or repeatedly hammering the API.
- **Location fallback.** If permission is denied, the app falls back to NYC and shows a non-blocking banner. This keeps the reviewer's experience smooth even if they tap "Don't allow" on the simulator prompt.
- **Animation polish.** Cards behind the top get a slight scale + Y offset for depth, and the dismiss animation uses `easeOut` over 0.35s so it feels intentional rather than abrupt.
- **Dedupe by ID across pages.** Yelp occasionally returns overlap when paging; the view model filters duplicates before append.

### Skipped or done quickly

- **No unit tests.** The protocol abstractions are there so tests can drop in, but I did not write them. With another hour I would mock the Yelp client and assert pagination + dedupe behavior, and mock favorites store for toggle persistence.
- **No image cache.** SwiftUI's `AsyncImage` re-fetches on every appear. For an endless feed in production I would swap in `Nuke` or `SDWebImage` (or a tiny `NSCache` wrapper) for memory + disk caching.
- **No retry / backoff on 429.** Errors bubble to a banner; I did not implement exponential backoff. With more time I would handle rate-limit responses explicitly.
- **No analytics, telemetry, or crash reporting.** Out of scope for a take-home; for production the next file I would add is a thin `Telemetry` protocol wired into the view model state transitions.
- **No deep link or detail view.** Tapping a card does nothing. For Fini's "playground" framing I would route to a detail screen with map + hours + tap-to-call, but that's a separate sprint.
- **No localization or accessibility audit beyond labels.** I added `accessibilityLabel` on the heart button and the rating view, but I did not run an Accessibility Inspector pass.

### Why SwiftUI over UIKit

For a card stack of 2-3 visible cards with simple slide animation, SwiftUI's declarative model and `AsyncImage` save real time over hand-wired `UICollectionView` cells and image loaders. UIKit would have given me more fine-grained gesture control (e.g., swipe-to-dismiss), but the assignment only specifies button-driven dismissal, so SwiftUI wins on time-to-build.

### Why async/await over Combine

Same reasoning: the data flow is "fetch coordinates → fetch page → append," which is naturally linear. Combine is more powerful for multi-stream reactive UIs, but it would have added boilerplate without buying me anything here.

---

## 3. If you finished with extra time, what improvements did you make that go above and beyond the requirements?

All three bonuses are implemented:

- **Landscape mode** — sizes are derived via `GeometryReader` instead of hard-coded constants, so the card stack reflows automatically. The deployment target is iOS 16+ so I lean on SwiftUI's adaptive layout rather than fighting Auto Layout.
- **Query input** — `ControlBarView` has a search bar bound to a local `@State` draft term. Tapping Return (`.submitLabel(.search)`) commits the term: the view model wipes the stack, resets `topIndex` and `nextOffset`, and refetches from page 0 with the new `term`.
- **Favorites toggle + persistence** — every card has a heart button that calls back into `toggleFavorite(_:)`. The view model keeps a `Set<String>` of Yelp IDs, persisted via `FavoritesStoring` (currently a `UserDefaults` implementation). The set is loaded in `init` so favorites survive across launches.

A few smaller polish items that were not asked for:

- **Gradient scrim** at the bottom of every card so the text remains legible regardless of the underlying image.
- **Placeholder image** with the restaurant's first letter on a warm gradient if Yelp's image URL is missing or fails to load.
- **Empty / loading / error states** — never a blank screen.
- **Distance shown in miles** under the address, derived from the `distance` field Yelp returns (meters → miles).
- **Half-star rendering** in `StarRatingView` so a 4.5 rating actually shows the half star instead of rounding.

### Things I would do next

If Fini ran this for real beyond the take-home:

1. **Image caching** layer (Nuke or NSCache wrapper).
2. **Unit tests** on `RestaurantStackViewModel` using a mock `YelpAPIClient` and `FavoritesStore` — pagination trigger, dedupe, search reset, and favorites persistence are the four test cases that pay back the abstraction work.
3. **Restaurant detail view** with map, hours, and "open in Yelp" deeplink.
4. **Swipe gestures** in addition to the button-driven flow.
5. **Rate-limit handling** with exponential backoff on 429s.
6. **Snapshot tests** for the card view so visual regressions surface in CI.
