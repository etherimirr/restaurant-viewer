# Restaurant Viewer — Fini iOS Take-Home

Card-based viewer for restaurants near the device, backed by Yelp.

## Setup

1. **Add the Yelp token.** Copy the secrets template and paste the Bearer token from the take-home assignment:
   ```sh
   cp RestaurantViewer/Services/Secrets.example.swift RestaurantViewer/Services/Secrets.swift
   # then edit Secrets.swift and set `yelpBearerToken`
   ```
   `Secrets.swift` is gitignored, so the token never lands in this public repo. The project will not compile until this file exists (the build references `Secrets.yelpBearerToken`).
2. **Open & run.** Open `RestaurantViewer.xcodeproj` in Xcode 15+, pick an iPhone simulator, and ⌘R. The deployment target is **iOS 16.0** (uses `AsyncImage`, `task`, `submitLabel`, and modern SwiftUI layout). The location-usage string and supported orientations are set via build settings (`GENERATE_INFOPLIST_FILE`), so there is no manual Info.plist step.
3. In the simulator, set **Features → Location → Custom Location** to a real lat/lon, or just tap "Don't Allow" — the app falls back to NYC so the demo still works.

## Architecture

- **MVVM** with a single `@MainActor` view model (`RestaurantStackViewModel`).
- **Services** are protocol-based (`YelpAPIClient`, `FavoritesStoring`) for testability.
- **Networking** uses `URLSession` + async/await.
- **Location** wraps `CLLocationManager` in a one-shot async API.
- **Pagination** triggers when 3 or fewer cards remain ahead of the top card. Yelp caps the result window at `offset + limit ≤ 240`, which we respect and gracefully stop paging.

## Features Implemented

| Requirement | Status |
|---|---|
| Yelp + Core Location | ✅ |
| Stack of cards with name, image, rating | ✅ |
| Next button: dismiss animates left | ✅ |
| Previous button: animates back from left | ✅ |
| Auto-load more near end of stack | ✅ |
| Endless seamless feed | ✅ (capped by Yelp's 240 offset window) |
| Creative UI | ✅ (gradient scrim, depth-layered stack, materials) |
| **BONUS** landscape mode | ✅ (GeometryReader-based sizing) |
| **BONUS** query input | ✅ (search bar in ControlBarView) |
| **BONUS** favorites toggle + persist | ✅ (UserDefaults) |

## Testing

End-to-end UI tests live in `RestaurantViewerUITests/` (XCUITest). They launch the
real app with the `-uitest-mock` launch argument, which makes `AppEnvironment`
inject deterministic dependencies — a mock Yelp client, a stub location provider,
and an in-memory favorites store — so the tests never touch the network or trigger
a location prompt. Run them with **⌘U** (or **Product → Test**) on any simulator.

Covered flows: initial card load, Next/Previous navigation, seamless pagination
past the first page, search-term reset, and the favorite toggle. The app exposes
accessibility identifiers (`topCardTitle`, `nextButton`, `previousButton`,
`searchField`, `favoriteButton`) so assertions target the front card reliably.

> Verified: builds clean and all 5 UI tests pass on the iOS 18.6 simulator
> (Xcode 16.4, iPhone 16).

## Trade-offs

See `design.md` and `WRITEUP.md` for full reasoning. Highlights:

- **SwiftUI over UIKit** for speed of build + clean animation API.
- **Async/await over Combine** — sufficient for this scope.
- **Top + 2 cards rendered** (not full collection view) — avoids memory churn for an endless feed.
- **NYC fallback** when location is denied — keeps the demo usable for reviewers.
- **No unit tests** in the 3-hour budget; services are protocol-backed so tests can drop in.

## File Layout

```
RestaurantViewer.xcodeproj              # open this
RestaurantViewer/
├── App/RestaurantViewerApp.swift
├── Assets.xcassets                     # AppIcon + AccentColor
├── Models/
│   ├── Restaurant.swift
│   └── YelpSearchResponse.swift
├── Services/
│   ├── YelpConfig.swift                # endpoint + paging constants; reads token from Secrets
│   ├── Secrets.example.swift           # token template (committed)
│   ├── Secrets.swift                   # real token (gitignored — create from template)
│   ├── YelpAPIClient.swift             # async URLSession client
│   ├── LocationManager.swift           # async wrapper around CLLocationManager
│   └── FavoritesStore.swift            # UserDefaults
├── ViewModels/RestaurantStackViewModel.swift
└── Views/
    ├── ContentView.swift               # root
    ├── CardStackView.swift             # ZStack + depth
    ├── RestaurantCard.swift            # single card
    ├── ControlBarView.swift            # search + prev/next
    ├── ErrorBannerView.swift
    └── StarRatingView.swift
```

## How to submit

The assignment asks for a **view-only Google Doc, public GitHub link, or similar file link**.

This repo is already a git repository with incremental commits that trace the build order (scaffold → models → networking → location → view model → views → bonuses → project/docs). To publish:

1. Create a fresh **public** GitHub repo and push:
   ```sh
   git remote add origin <your-public-repo-url>
   git push -u origin main
   ```
2. Confirm `Secrets.swift` is **not** in the pushed tree (it is gitignored; only `Secrets.example.swift` should appear).
3. Send the repo URL to Ashley with `WRITEUP.md` linked or pasted into the email.
