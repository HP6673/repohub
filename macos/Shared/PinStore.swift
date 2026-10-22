import Foundation

/// A repository pinned from the app and shown in the widgets.
struct PinnedRepo: Codable, Hashable, Identifiable {
    var owner: String
    var name: String
    /// The repository page on github.com.
    var url: URL
    /// The deployed website: the repo's homepage, or its GitHub Pages URL.
    var siteURL: URL?

    var id: String { owner.lowercased() + "/" + name.lowercased() }

    static let samples: [PinnedRepo] = [
        "portfolio", "client-site", "landing-page", "docs", "dashboard", "blog",
        "store-front", "api-server", "design-system", "status-page",
    ].map {
        PinnedRepo(
            owner: "LJ-Web-Management",
            name: $0,
            url: URL(string: "https://github.com/LJ-Web-Management/\($0)")!,
            siteURL: URL(string: "https://lj-web-management.github.io/\($0)/")
        )
    }
}

/// Pins live in the shared App Group so the app and the widget extension see the same list.
enum PinStore {
    static let pinsKey = "pinnedRepos"
    static let scheme = "repohub"

    static var appGroupID: String {
        Bundle.main.object(forInfoDictionaryKey: "RepoHubAppGroup") as? String ?? "com.ljwebmanagement.repohub"
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> [PinnedRepo] {
        guard let data = defaults.data(forKey: pinsKey),
              let pins = try? JSONDecoder().decode([PinnedRepo].self, from: data)
        else { return [] }
        return pins
    }

    static func save(_ pins: [PinnedRepo]) {
        guard let data = try? JSONEncoder().encode(pins) else { return }
        defaults.set(data, forKey: pinsKey)
    }

    /// Widgets hand their links to the containing app, which forwards them to the default browser.
    static func widgetLink(to target: URL) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "url", value: target.absoluteString)]
        return components.url!
    }

    /// Unwraps a link built by `widgetLink(to:)`. Only http(s) targets are accepted.
    static func target(from url: URL) -> URL? {
        guard url.scheme == scheme, url.host == "open",
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == "url" })?.value,
              let target = URL(string: value),
              ["http", "https"].contains(target.scheme?.lowercased() ?? "")
        else { return nil }
        return target
    }
}
