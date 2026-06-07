# Write-Up

A few notes on how I approached this. (Per the brief, the time on this write-up isn't counted against the budget.)

## 1. How long did you spend, and what was the hardest part?

I spent about three hours on the core app: reading the brief and sketching the architecture, then building it out, the Yelp client and models, the Core Location wrapper, the view model with pagination, and the card UI with the slide animation. After that I put in some extra time on the things the brief says you can add if you have any left over: a UI test suite, the landscape layout, and getting the project building cleanly in Xcode. Those are in question 3.

The hardest part was the card-stack animation. The idea is simple, the top card slides off to the left and the next one moves forward, but getting SwiftUI to animate it without flickering took some trial and error. The trouble was the interplay between zIndex, the transition, and which value the animation is keyed on. What finally worked was rendering only the top card plus the two behind it (topIndex through topIndex+2) and animating the index itself, which keeps SwiftUI's diffing predictable.

The other awkward piece was wrapping CLLocationManager in an async call. Its delegate callbacks have to be bridged to a continuation that resumes exactly once, and you have to be careful with the "permission not decided yet, then prompt, then first fix" path so you never resume it twice.

## 2. What trade-offs did you make?

Things I deliberately spent time on:

- I put the Yelp client and the favorites store behind protocols. That's slightly more than a three-hour toy needs, but the brief says to treat it like production code, and it's cheap to do. It also made the app testable later on.
- Pagination has a real edge case: Yelp won't let you page past offset 240. The view model tracks that and just stops fetching, instead of erroring or hammering the API.
- If location permission is denied, the app falls back to NYC and shows a small dismissible banner, so a reviewer who taps "Don't Allow" still gets a working app.
- Yelp occasionally returns the same place on two different pages, so I dedupe by id before appending.

Things I skipped or kept quick:

- No image caching. AsyncImage refetches on every appear; in production I'd drop in something like Nuke or a small NSCache wrapper.
- No retry/backoff on a 429. For now errors just surface in the banner.
- No analytics, and no detail screen yet. Tapping a card doesn't do anything; a detail view with a map, hours, and tap-to-call would be the obvious next screen.
- Accessibility is labels-only. I added labels on the heart and the rating but didn't do a full Accessibility Inspector pass.

On the two framework calls: I went with SwiftUI because for a two-or-three-card stack with a button-driven slide, the declarative layout and the built-in AsyncImage are just faster than hand-wiring UICollectionView cells and image loading. UIKit would give finer gesture control, but the brief only asks for button dismissal. And I used async/await rather than Combine because the flow is linear (get location, fetch a page, append), so Combine would have been more boilerplate for no real benefit here.

## 3. What did you add with the extra time?

All three bonuses are in:

- Landscape. The card sizes off GeometryReader rather than fixed numbers, and the layout switches to a side-by-side arrangement when the device is wide (card on the left, title and controls on the right) so nothing overlaps. I caught and fixed a bug here where the title and the card caption were getting clipped in landscape.
- Search. The control bar has a search field; submitting a new term clears the stack and refetches from the first page.
- Favorites. Each card has a heart that toggles a favorite, stored as a set of Yelp ids in UserDefaults so it survives relaunches.

A few smaller things I added that weren't asked for: a gradient at the bottom of each card so the text stays readable over any photo, a letter placeholder when an image is missing or fails to load, proper loading/empty/error states instead of a blank screen, distance shown in miles, and half-star ratings so a 4.5 actually shows a half star.

I also wrote an XCUITest suite (five tests) that drives the real app: first card loads, next/previous, pagination past the first page, search reset, and the favorite toggle. To make that work without depending on the network, I added a launch flag that swaps in a mock Yelp client and a fixed location, and I tagged the front card with accessibility identifiers so a test can tell which card is on top of the stack. The suite passes on the iOS 18.6 simulator.

If this were going further, the next things I'd pick up are an image cache, view-model unit tests for the pagination and dedupe logic on their own, a restaurant detail screen, swipe gestures alongside the buttons, and 429 backoff.

## Note on the requirements

The requirements list mentions Android (SDK >= 23) alongside iOS. I read that as the shared cross-platform wording, since the same brief covers both tracks. This is the iOS submission, so it covers iPhone (including Plus sizes) and adapts across screen sizes and orientation.
