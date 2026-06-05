import SwiftUI

/// Root view. Owns the single `RestaurantStackViewModel` instance for the app.
struct ContentView: View {
    @StateObject private var viewModel: RestaurantStackViewModel

    /// Defaults to the app environment (live, or mock under UI tests). Tests and
    /// previews can inject a view model directly.
    init(viewModel: @autoclosure @escaping () -> RestaurantStackViewModel = AppEnvironment.makeRootViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Nearby")
                    .font(.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                CardStackView(viewModel: viewModel)

                ControlBarView(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            if let banner = viewModel.bannerMessage {
                ErrorBannerView(message: banner) {
                    viewModel.bannerMessage = nil
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .zIndex(1000)
            }
        }
        .task { await viewModel.onAppear() }
        .animation(.easeInOut(duration: 0.25), value: viewModel.bannerMessage)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    ContentView()
}
