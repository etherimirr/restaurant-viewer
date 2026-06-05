import Foundation

/// Wire-format envelope from Yelp's `/businesses/search` endpoint.
/// Kept private to the networking layer; views see `Restaurant` instead.
struct YelpSearchResponse: Decodable {
    let businesses: [YelpBusiness]
    let total: Int
}

struct YelpBusiness: Decodable {
    let id: String
    let name: String
    let imageURL: String?
    let rating: Double
    let reviewCount: Int
    let location: Location?
    let distance: Double?

    struct Location: Decodable {
        let address1: String?
        let city: String?
        let zipCode: String?

        enum CodingKeys: String, CodingKey {
            case address1, city
            case zipCode = "zip_code"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, rating, location, distance
        case imageURL = "image_url"
        case reviewCount = "review_count"
    }

    /// Maps wire format to the domain model.
    func toRestaurant() -> Restaurant {
        let composedAddress: String = {
            let parts = [location?.address1, location?.city, location?.zipCode]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            return parts.joined(separator: ", ")
        }()

        return Restaurant(
            id: id,
            name: name,
            imageURL: imageURL.flatMap(URL.init(string:)),
            rating: rating,
            reviewCount: reviewCount,
            address: composedAddress,
            distanceMeters: distance
        )
    }
}
