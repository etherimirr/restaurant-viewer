import Foundation

/// Builds the root view model, choosing live or mock dependencies.
///
/// Under UI tests we launch the app with `-uitest-mock` so the stack is fed
/// deterministic data with no network or location prompt. The mock branch is
/// `DEBUG`-only, so release builds always use the live services.
enum AppEnvironment {
    static let uiTestMockArgument = "-uitest-mock"

    @MainActor
    static func makeRootViewModel() -> RestaurantStackViewModel {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(uiTestMockArgument) {
            return RestaurantStackViewModel(
                api: MockYelpAPIClient(),
                location: StubLocationProvider(),
                favorites: InMemoryFavoritesStore()
            )
        }
        #endif
        return RestaurantStackViewModel()
    }
}
