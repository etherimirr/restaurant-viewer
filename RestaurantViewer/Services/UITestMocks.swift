#if DEBUG
import Foundation
import CoreLocation

/// Deterministic in-process test doubles used when the app launches under UI
/// tests (`-uitest-mock`). Kept in the app target (DEBUG-only) because XCUITest
/// is black-box: the app must inject these itself. Also reusable by unit tests.

/// Returns ordered, predictable restaurants so a UI test can assert that the
/// top card changes on Next/Previous and reflects a new search term.
struct MockYelpAPIClient: YelpAPIClient {
    /// Total available results across all pages, to exercise pagination.
    var total = 120

    func search(
        term: String,
        coordinate: CLLocationCoordinate2D,
        offset: Int,
        limit: Int
    ) async throws -> [Restaurant] {
        guard offset < total else { return [] }
        let end = min(offset + limit, total)
        let label = Self.displayLabel(for: term)
        return (offset..<end).map { i -> Restaurant in
            let number: String = String(format: "%02d", i + 1)
            let rating: Double = Double(i % 5) + 0.5
            let reviews: Int = 100 + i
            let distance: Double = Double((i + 1) * 100)
            return Restaurant(
                id: "mock-\(label)-\(i)",
                name: "\(label) \(number)",
                imageURL: nil, // nil -> letter placeholder, so tests never hit the network
                rating: rating,
                reviewCount: reviews,
                address: "\(i + 1) Test Street",
                distanceMeters: distance
            )
        }
    }

    /// "restaurants" -> "Bistro"; any other term -> its capitalized first word,
    /// so a search for "ramen" yields cards titled "Ramen 01", "Ramen 02"…
    static func displayLabel(for term: String) -> String {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "restaurants" { return "Bistro" }
        let first = trimmed.split(separator: " ").first.map(String.init) ?? trimmed
        return first.prefix(1).uppercased() + first.dropFirst().lowercased()
    }
}

/// Fixed coordinate; never prompts for permission.
struct StubLocationProvider: LocationProviding {
    var coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    func currentCoordinate() async throws -> CLLocationCoordinate2D { coordinate }
}

/// Favorites kept in memory so UI tests stay isolated from real UserDefaults.
final class InMemoryFavoritesStore: FavoritesStoring {
    private var ids: Set<String> = []
    func load() -> Set<String> { ids }
    func save(_ ids: Set<String>) { self.ids = ids }
}
#endif
