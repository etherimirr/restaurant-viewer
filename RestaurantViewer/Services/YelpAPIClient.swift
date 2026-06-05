import Foundation
import CoreLocation

/// Protocol-based client so the ViewModel can be tested with a mock.
protocol YelpAPIClient {
    func search(
        term: String,
        coordinate: CLLocationCoordinate2D,
        offset: Int,
        limit: Int
    ) async throws -> [Restaurant]
}

/// Live implementation backed by URLSession + async/await.
struct LiveYelpAPIClient: YelpAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    enum YelpError: Error, LocalizedError {
        case badURL
        case http(status: Int)
        case decoding(Error)
        case offsetExceeded

        var errorDescription: String? {
            switch self {
            case .badURL: return "Could not build the Yelp request URL."
            case .http(let status):
                return "Yelp returned HTTP \(status)."
            case .decoding(let error):
                return "Could not parse Yelp response: \(error.localizedDescription)"
            case .offsetExceeded:
                return "Yelp does not allow paging past \(YelpConfig.maxOffset) results."
            }
        }
    }

    func search(
        term: String,
        coordinate: CLLocationCoordinate2D,
        offset: Int,
        limit: Int
    ) async throws -> [Restaurant] {
        // Yelp caps offset + limit at 240; respect that and surface to caller.
        guard offset + limit <= YelpConfig.maxOffset else {
            throw YelpError.offsetExceeded
        }

        var components = URLComponents(
            url: YelpConfig.baseURL.appendingPathComponent("businesses/search"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "sort_by", value: "best_match")
        ]

        guard let url = components?.url else { throw YelpError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(YelpConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw YelpError.http(status: -1)
        }

        // 429 rate limit -> bubble up; caller decides whether to backoff.
        guard (200..<300).contains(http.statusCode) else {
            throw YelpError.http(status: http.statusCode)
        }

        do {
            let envelope = try decoder.decode(YelpSearchResponse.self, from: data)
            return envelope.businesses.map { $0.toRestaurant() }
        } catch {
            throw YelpError.decoding(error)
        }
    }
}
