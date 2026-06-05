import SwiftUI

/// Renders the top N cards as a layered ZStack. Top card animates off to the
/// left on `next`, and the previous card animates back in from the left on
/// `previous`. Cards behind get a small depth offset to give the stack feel.
struct CardStackView: View {
    @ObservedObject var viewModel: RestaurantStackViewModel

    /// How many cards to render behind the top one (visual depth only).
    private let visibleBehind = 2

    /// Width of the card relative to the available width.
    private let cardWidthRatio: CGFloat = 0.92

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width * cardWidthRatio
            // Tall card on portrait, more square on landscape.
            let cardHeight = min(geo.size.height * 0.85, cardWidth * 1.35)

            ZStack {
                if viewModel.restaurants.isEmpty {
                    emptyOrLoadingState
                } else {
                    ForEach(visibleCardIndices.reversed(), id: \.self) { index in
                        cardView(at: index, width: cardWidth, height: cardHeight)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            .zIndex(Double(viewModel.topIndex - index + 100))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeOut(duration: 0.35), value: viewModel.topIndex)
    }

    /// Indices to render: top + up to `visibleBehind` cards behind.
    private var visibleCardIndices: [Int] {
        let upperBound = min(viewModel.topIndex + visibleBehind, viewModel.restaurants.count - 1)
        guard upperBound >= viewModel.topIndex else { return [] }
        return Array(viewModel.topIndex...upperBound)
    }

    @ViewBuilder
    private func cardView(at index: Int, width: CGFloat, height: CGFloat) -> some View {
        let restaurant = viewModel.restaurants[index]
        let stackOffset = index - viewModel.topIndex  // 0 = top
        let scale = 1.0 - CGFloat(stackOffset) * 0.04
        let yOffset = CGFloat(stackOffset) * 12

        RestaurantCard(
            restaurant: restaurant,
            isFavorite: viewModel.isFavorite(restaurant.id),
            onToggleFavorite: { viewModel.toggleFavorite(restaurant.id) },
            isTopCard: stackOffset == 0
        )
        .frame(width: width, height: height)
        .scaleEffect(scale)
        .offset(y: yOffset)
        .allowsHitTesting(stackOffset == 0)
    }

    @ViewBuilder
    private var emptyOrLoadingState: some View {
        if viewModel.isLoadingInitial {
            ProgressView("Finding places near you…")
                .tint(.secondary)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("No results yet")
                    .font(.headline)
                Text("Try a different search term.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
