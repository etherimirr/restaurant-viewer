import Foundation

/// Yelp API configuration.
///
/// The Bearer token is read from `Secrets.swift`, which is gitignored so the
/// credential never lands in the public repo. In production this would come
/// from the Keychain or a build-time secret store; for the take-home, a
/// gitignored file keeps the token out of source control while staying simple.
/// See `Secrets.example.swift` for setup.
enum YelpConfig {
    static let bearerToken: String = Secrets.yelpBearerToken

    static let baseURL = URL(string: "https://api.yelp.com/v3")!

    /// Yelp `/businesses/search` caps `offset + limit` at 240.
    static let maxOffset = 240

    /// Per-page result count. Yelp allows up to 50.
    static let pageLimit = 50
}
