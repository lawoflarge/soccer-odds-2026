import Foundation

@MainActor
final class PredictionsService: ObservableObject {
    @Published private(set) var matches: [Match] = []
    @Published private(set) var lastUpdated: String?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    private let url: URL
    private let session: URLSession
    private let cacheURL: URL

    init(url: URL = Config.predictionsURL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheURL = caches.appendingPathComponent("predictions.json")
        loadFromCache()
    }

    static func decode(_ data: Data) throws -> PredictionsFile {
        try JSONDecoder().decode(PredictionsFile.self, from: data)
    }

    /// Decode `data`, publish its matches, and persist it as the offline cache.
    func apply(_ data: Data) throws {
        let file = try Self.decode(data)
        self.matches = file.matches
        self.lastUpdated = file.updated
        try? data.write(to: cacheURL)
    }

    private func loadFromCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let file = try? Self.decode(data) else { return }
        self.matches = file.matches
        self.lastUpdated = file.updated
    }

    /// Fetch the live feed; on failure keep cached data and surface a message.
    func refresh() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            try apply(data)
        } catch {
            loadError = matches.isEmpty
                ? "Couldn't load predictions. Check your connection and try again."
                : "Showing last saved data — couldn't reach the server."
        }
    }
}
