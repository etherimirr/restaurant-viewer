import Foundation

/// Template for the gitignored `Secrets.swift`.
///
/// Setup (one-time, after cloning):
/// 1. Copy this file to `Secrets.swift` in the same folder.
/// 2. Paste the Yelp Bearer token from the Fini take-home assignment.
///
/// `Secrets.swift` is listed in `.gitignore` so the token never lands in the
/// public repo. The build references `Secrets.yelpBearerToken`, so the project
/// will not compile until `Secrets.swift` exists.
enum Secrets {
    static let yelpBearerToken = "YOUR_YELP_BEARER_TOKEN"
}
