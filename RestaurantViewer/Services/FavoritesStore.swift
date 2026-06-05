import Foundation

/// Persists the set of favorited restaurant IDs in UserDefaults.
///
/// BONUS feature. Wrapped in a protocol so the ViewModel doesn't bind to
/// UserDefaults directly; a unit test can swap in an in-memory store.
protocol FavoritesStoring {
    func load() -> Set<String>
    func save(_ ids: Set<String>)
}

struct UserDefaultsFavoritesStore: FavoritesStoring {
    private let defaults: UserDefaults
    private let key = "fini.favorites"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Set<String> {
        guard let array = defaults.array(forKey: key) as? [String] else {
            return []
        }
        return Set(array)
    }

    func save(_ ids: Set<String>) {
        defaults.set(Array(ids), forKey: key)
    }
}
