import SwiftUI

/// Renders a 0-5 star rating with half-star support.
struct StarRatingView: View {
    let rating: Double  // 0...5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                star(for: index)
            }
        }
        .accessibilityLabel("\(String(format: "%.1f", rating)) out of 5 stars")
    }

    private func star(for index: Int) -> some View {
        let cutoff = Double(index) + 0.5
        let full = rating >= Double(index + 1)
        let half = rating >= cutoff && !full

        let symbol: String = full ? "star.fill" : half ? "star.leadinghalf.filled" : "star"
        return Image(systemName: symbol)
            .foregroundStyle(.yellow)
            .font(.subheadline.weight(.semibold))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        StarRatingView(rating: 4.5)
        StarRatingView(rating: 3.0)
        StarRatingView(rating: 0.0)
    }
    .padding()
}
