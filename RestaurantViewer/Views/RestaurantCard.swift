import SwiftUI

/// Single card showing one restaurant. Heart icon (BONUS) lets the user
/// toggle favorite state via the binding-style closure.
struct RestaurantCard: View {
    let restaurant: Restaurant
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundImage

            // Gradient scrim so text remains readable over any image.
            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(restaurant.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer(minLength: 12)
                    favoriteButton
                }

                HStack(spacing: 8) {
                    StarRatingView(rating: restaurant.rating)
                    Text("(\(restaurant.reviewCount))")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(restaurant.displayAddress)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                    if let d = restaurant.displayDistance {
                        Text("· \(d)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
    }

    @ViewBuilder
    private var backgroundImage: some View {
        AsyncImage(url: restaurant.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholder
            case .empty:
                ZStack {
                    placeholder
                    ProgressView().tint(.white)
                }
            @unknown default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [.orange.opacity(0.8), .pink.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(String(restaurant.name.prefix(1)).uppercased())
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundStyle(isFavorite ? .pink : .white)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}

#Preview {
    RestaurantCard(
        restaurant: Restaurant(
            id: "1",
            name: "Joe's Pizza",
            imageURL: URL(string: "https://s3-media1.fl.yelpcdn.com/bphoto/abc/o.jpg"),
            rating: 4.5,
            reviewCount: 1024,
            address: "7 Carmine St, New York, 10014",
            distanceMeters: 432
        ),
        isFavorite: true,
        onToggleFavorite: {}
    )
    .padding()
    .frame(height: 480)
}
