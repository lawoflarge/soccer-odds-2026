import Foundation

final class FavoriteStore: ObservableObject {
    @Published var favoriteTeam: String? {
        didSet { defaults.set(favoriteTeam, forKey: key) }
    }

    private let defaults: UserDefaults
    private let key = "favoriteTeam"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.favoriteTeam = defaults.string(forKey: key)
    }
}
