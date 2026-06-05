import SwiftUI

/// Prev / Next buttons and (BONUS) search input.
struct ControlBarView: View {
    @ObservedObject var viewModel: RestaurantStackViewModel

    /// Local mirror so typing doesn't fire a request on every keystroke.
    /// We commit on submit (Return key) or when the field loses focus.
    @State private var draftTerm: String = "restaurants"
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            searchBar

            HStack(spacing: 16) {
                navigationButton(
                    systemImage: "arrow.left",
                    label: "Previous",
                    enabled: viewModel.canShowPrevious,
                    action: viewModel.showPrevious
                )
                navigationButton(
                    systemImage: "arrow.right",
                    label: "Next",
                    enabled: viewModel.canShowNext,
                    action: viewModel.showNext
                )
            }
        }
        .onAppear { draftTerm = viewModel.searchTerm }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("restaurants, coffee, ramen…", text: $draftTerm)
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { commitSearch() }
            if !draftTerm.isEmpty {
                Button {
                    draftTerm = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
    }

    private func navigationButton(
        systemImage: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(label).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(enabled ? Color.accentColor : Color.gray.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func commitSearch() {
        searchFocused = false
        Task { await viewModel.applyNewSearchTerm(draftTerm) }
    }
}
