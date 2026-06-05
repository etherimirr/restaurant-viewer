import Foundation
import CoreLocation
import SwiftUI

/// Owns the card-stack state and orchestrates location + Yelp + favorites.
/// `@MainActor` so all `@Published` mutations land on the main thread.
@MainActor
final class RestaurantStackViewModel: ObservableObject {

    // MARK: - Published state

    /// Full list of restaurants fetched so far. Append-only.
    @Published private(set) var restaurants: [Restaurant] = []

    /// Index of the top card. Advances on Next, retreats on Previous.
    @Published private(set) var topIndex: Int = 0

    @Published private(set) var isLoadingInitial: Bool = false
    @Published private(set) var isLoadingMore: Bool = false

    /// Non-fatal banner messages: location denied, network blip, etc.
    @Published var bannerMessage: String?

    /// Favorited restaurant IDs. BONUS feature.
    @Published private(set) var favoriteIDs: Set<String> = []

    /// Search term. BONUS bind to the search box in ControlBarView.
    @Published var searchTerm: String = "restaurants"

    // MARK: - Dependencies

    private let api: YelpAPIClient
    private let location: LocationProviding
    private let favorites: FavoritesStoring

    // MARK: - Pagination + location cache

    private var nextOffset: Int = 0
    private var didReachEndOfYelp: Bool = false
    private var coordinate: CLLocationCoordinate2D?

    /// Trigger pagination when this many cards remain ahead of the top.
    private let prefetchThreshold = 3

    init(
        api: YelpAPIClient = LiveYelpAPIClient(),
        location: LocationProviding = LocationManager(),
        favorites: FavoritesStoring = UserDefaultsFavoritesStore()
    ) {
        self.api = api
        self.location = location
        self.favorites = favorites
        self.favoriteIDs = favorites.load()
    }

    // MARK: - Public lifecycle

    /// Called once on appear. Resolves location, fetches first page.
    func onAppear() async {
        guard !isLoadingInitial && restaurants.isEmpty else { return }
        isLoadingInitial = true
        defer { isLoadingInitial = false }

        do {
            self.coordinate = try await location.currentCoordinate()
        } catch {
            // Fallback to NYC + show a banner so the demo still works.
            self.coordinate = LocationManager.fallbackCoordinate
            self.bannerMessage = (error as? LocalizedError)?.errorDescription
                ?? "Using a default location."
        }
        await loadPage()
    }

    // MARK: - Card navigation

    func showNext() {
        guard topIndex < restaurants.count - 1 else { return }
        topIndex += 1
        prefetchIfNeeded()
    }

    func showPrevious() {
        guard topIndex > 0 else { return }
        topIndex -= 1
    }

    var canShowNext: Bool { topIndex < restaurants.count - 1 }
    var canShowPrevious: Bool { topIndex > 0 }

    // MARK: - Favorites (BONUS)

    func isFavorite(_ id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggleFavorite(_ id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        favorites.save(favoriteIDs)
    }

    // MARK: - Search term change (BONUS)

    /// Reset the stack and refetch with the new term.
    func applyNewSearchTerm(_ term: String) async {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != searchTerm else { return }
        searchTerm = trimmed
        // Hard reset: empty list, reset offset/topIndex, refetch from page 0.
        restaurants = []
        topIndex = 0
        nextOffset = 0
        didReachEndOfYelp = false
        await loadPage()
    }

    // MARK: - Pagination

    private func prefetchIfNeeded() {
        let remaining = restaurants.count - topIndex
        guard remaining <= prefetchThreshold else { return }
        guard !isLoadingMore, !didReachEndOfYelp else { return }
        Task { await loadPage() }
    }

    private func loadPage() async {
        guard let coord = coordinate else { return }
        guard !didReachEndOfYelp else { return }

        let term = searchTerm.isEmpty ? "restaurants" : searchTerm

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await api.search(
                term: term,
                coordinate: coord,
                offset: nextOffset,
                limit: YelpConfig.pageLimit
            )

            // Dedupe by ID in case Yelp returns overlapping results between pages.
            let existingIDs = Set(restaurants.map(\.id))
            let fresh = page.filter { !existingIDs.contains($0.id) }
            restaurants.append(contentsOf: fresh)

            nextOffset += YelpConfig.pageLimit
            if nextOffset + YelpConfig.pageLimit > YelpConfig.maxOffset || page.isEmpty {
                didReachEndOfYelp = true
            }
        } catch LiveYelpAPIClient.YelpError.offsetExceeded {
            didReachEndOfYelp = true
        } catch {
            bannerMessage = (error as? LocalizedError)?.errorDescription
                ?? "Could not load more restaurants. Tap Next to try again."
        }
    }
}
