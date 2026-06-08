import Foundation
import Observation

@MainActor
@Observable
final class TrackRecordService {
    private(set) var trackRecord: TrackRecord?
    private(set) var isLoading = false
    private(set) var loadError: String?

    private let url: URL
    private let session: URLSession
    private let cacheURL: URL

    init(url: URL = Config.trackRecordURL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheURL = caches.appendingPathComponent("track_record.json")
        loadFromCache()
    }

    static func decode(_ data: Data) throws -> TrackRecord {
        try JSONDecoder().decode(TrackRecord.self, from: data)
    }

    func apply(_ data: Data) throws {
        let tr = try Self.decode(data)
        self.trackRecord = tr
        try? data.write(to: cacheURL)
    }

    private func loadFromCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let tr = try? Self.decode(data) else { return }
        self.trackRecord = tr
    }

    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-screenshotData") {
            if let u = Bundle.main.url(forResource: "sample-track-record", withExtension: "json"),
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
            loadError = trackRecord == nil
                ? "Couldn't load track record. Check your connection and try again."
                : "Showing last saved data — couldn't reach the server."
        }
    }
}
