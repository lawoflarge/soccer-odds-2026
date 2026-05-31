import SwiftUI

struct FlagView: View {
    let team: String

    private static let flags: [String: String] = {
        guard let url = Bundle.main.url(forResource: "teams", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return map
    }()

    var body: some View {
        Text(Self.flags[team] ?? "🏳️")
            .accessibilityHidden(true)
    }
}
