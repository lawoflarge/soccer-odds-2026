import Foundation
import Observation

@MainActor
@Observable
final class OddsHistoryService {
    private(set) var history: OddsHistory = [:]
    private(set) var isLoading = false
    private(set) var loadError: String?

    private let url: URL
    private let session: URLSession
    private let cacheURL: URL

    init(url: URL = Config.oddsHistoryURL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheURL = caches.appendingPathComponent("odds_history.json")
        loadFromCache()
    }

    static func decode(_ data: Data) throws -> OddsHistory {
        try JSONDecoder().decode(OddsHistory.self, from: data)
    }

    func apply(_ data: Data) throws {
        let h = try Self.decode(data)
        self.history = h
        try? data.write(to: cacheURL)
    }

    private func loadFromCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let h = try? Self.decode(data) else { return }
        self.history = h
    }

    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-screenshotData") {
            if let u = Bundle.main.url(forResource: "sample-odds-history", withExtension: "json"),
               let d = try? Data(contentsOf: u) { try? apply(d) }
            return
        }
        #endif
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
            loadError = history.isEmpty
                ? "Couldn't load odds history. Check your connection and try again."
                : "Showing last saved data — couldn't reach the server."
        }
    }

    /// Returns the snapshots for a given match ID, sorted ascending by date.
    func snapshots(for matchId: String) -> [OddsSnapshot] {
        (history[matchId] ?? []).sorted { $0.t < $1.t }
    }
}
