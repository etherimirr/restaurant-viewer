import SwiftUI

/// Root view. Owns the single `RestaurantStackViewModel` instance for the app.
struct ContentView: View {
    /// Built from the app environment: live services normally, or deterministic
    /// mocks when launched under UI tests (`-uitest-mock`). See `AppEnvironment`.
    @StateObject private var viewModel = AppEnvironment.makeRootViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient.ignoresSafeArea()

            GeometryReader { geo in
                // Side-by-side in landscape so the card's caption and the
                // controls never overlap in the short vertical space.
                if geo.size.width > geo.size.height {
                    landscapeLayout
                } else {
                    portraitLayout
                }
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

    private var portraitLayout: some View {
        VStack(spacing: 16) {
            header
            CardStackView(viewModel: viewModel)
            ControlBarView(viewModel: viewModel)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    private var landscapeLayout: some View {
        HStack(spacing: 16) {
            CardStackView(viewModel: viewModel)

            VStack(alignment: .leading, spacing: 16) {
                header
                Spacer(minLength: 0)
                ControlBarView(viewModel: viewModel)
            }
            .frame(width: 320)
            .padding(.trailing, 20)
            .padding(.vertical, 8)
        }
        .padding(.leading, 8)
    }

    private var header: some View {
        Text("Nearby")
            .font(.largeTitle.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
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
