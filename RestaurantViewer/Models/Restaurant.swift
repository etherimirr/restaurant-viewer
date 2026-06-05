import Foundation

/// Domain model for a restaurant card. Decoupled from Yelp's wire format so
/// we can swap data sources later without rippling changes into views.
struct Restaurant: Identifiable, Hashable {
    let id: String
    let name: String
    let imageURL: URL?
    let rating: Double
    let reviewCount: Int
    let address: String
    let distanceMeters: Double?

    /// Compact display address, falling back gracefully.
    var displayAddress: String {
        address.isEmpty ? "Address unavailable" : address
    }

    /// Distance string in miles, rounded to one decimal. Returns nil if unknown.
    var displayDistance: String? {
        guard let meters = distanceMeters else { return nil }
        let miles = meters / 1609.34
        return String(format: "%.1f mi", miles)
    }
}
