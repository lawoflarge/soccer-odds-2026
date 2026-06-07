import Foundation
import Observation

@MainActor
@Observable
final class SimulationService {
    private(set) var simulation: TournamentSimulation?
    private(set) var isLoading = false
    private(set) var loadError: String?

    private let url: URL
    private let session: URLSession
    private let cacheURL: URL

    init(url: URL = Config.simulationURL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheURL = caches.appendingPathComponent("simulation.json")
        loadFromCache()
    }

    static func decode(_ data: Data) throws -> TournamentSimulation {
        try JSONDecoder().decode(TournamentSimulation.self, from: data)
    }

    func apply(_ data: Data) throws {
        let sim = try Self.decode(data)
        self.simulation = sim
        try? data.write(to: cacheURL)
    }

    private func loadFromCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let sim = try? Self.decode(data) else { return }
        self.simulation = sim
    }

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
            loadError = simulation == nil
                ? "Couldn't load simulation data. Check your connection and try again."
                : "Showing last saved data — couldn't reach the server."
        }
    }
}
