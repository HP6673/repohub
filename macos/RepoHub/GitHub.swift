import Foundation

enum Account: String, CaseIterable, Identifiable {
    case lj = "LJ-Web-Management"
    case hp = "HP6673"

    var id: String { rawValue }
    var login: String { rawValue }
}

struct Repo: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let htmlUrl: URL
    let homepage: String?
    let hasPages: Bool
    let fork: Bool
    let archived: Bool
    let pushedAt: Date?
    let owner: Owner

    struct Owner: Decodable, Hashable {
        let login: String
    }

    /// The repo's homepage field, when it holds a usable http(s) URL.
    var homepageURL: URL? {
        guard var value = homepage?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return nil }
        if !value.contains("://") { value = "https://" + value }
        guard let url = URL(string: value), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }

    /// The default GitHub Pages address for this repo.
    var defaultPagesURL: URL {
        let host = owner.login.lowercased() + ".github.io"
        if name.lowercased() == host {
            return URL(string: "https://\(host)/")!
        }
        return URL(string: "https://\(host)/\(name)/")!
    }
}

enum GitHubError: LocalizedError {
    case rateLimited(reset: Date?)
    case status(Int)

    var errorDescription: String? {
        switch self {
        case .rateLimited(let reset):
            if let reset {
                return "GitHub API rate limit reached. Try again after \(reset.formatted(date: .omitted, time: .shortened))."
            }
            return "GitHub API rate limit reached. Try again in a few minutes."
        case .status(let code):
            return "GitHub responded with \(code)."
        }
    }
}

enum GitHub {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return data }
        if http.statusCode == 429 || (http.statusCode == 403 && http.value(forHTTPHeaderField: "x-ratelimit-remaining") == "0") {
            let reset = http.value(forHTTPHeaderField: "x-ratelimit-reset").flatMap(TimeInterval.init).map(Date.init(timeIntervalSince1970:))
            throw GitHubError.rateLimited(reset: reset)
        }
        guard (200..<300).contains(http.statusCode) else { throw GitHubError.status(http.statusCode) }
        return data
    }

    static func repos(for account: Account) async throws -> [Repo] {
        var all: [Repo] = []
        var page = 1
        while true {
            let url = URL(string: "https://api.github.com/users/\(account.login)/repos?per_page=100&page=\(page)&sort=pushed")!
            let batch = try decoder.decode([Repo].self, from: try await get(url))
            all += batch
            if batch.count < 100 { break }
            page += 1
        }
        return all
    }

    /// The deployed website for a repo: its homepage if set, otherwise its GitHub Pages
    /// URL (including a custom Pages domain when one is configured).
    static func siteURL(for repo: Repo) async -> URL? {
        if let homepage = repo.homepageURL { return homepage }
        guard repo.hasPages else { return nil }

        struct Pages: Decodable { let htmlUrl: URL? }
        let endpoint = URL(string: "https://api.github.com/repos/\(repo.owner.login)/\(repo.name)/pages")!
        if let data = try? await get(endpoint),
           let pages = try? decoder.decode(Pages.self, from: data),
           let url = pages.htmlUrl {
            return url
        }
        return repo.defaultPagesURL
    }
}
