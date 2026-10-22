import Foundation
import WidgetKit

@MainActor
final class RepoModel: ObservableObject {
    @Published private(set) var repos: [Account: [Repo]] = [:]
    @Published private(set) var errors: [Account: String] = [:]
    @Published private(set) var loading: Set<Account> = []
    @Published private(set) var pins: [PinnedRepo] = PinStore.load()

    func load(_ account: Account, force: Bool = false) async {
        if repos[account] != nil && !force { return }
        loading.insert(account)
        defer { loading.remove(account) }
        do {
            let fetched = try await GitHub.repos(for: account)
            repos[account] = fetched
            errors[account] = nil
            await refreshSiteURLs(using: fetched)
        } catch {
            errors[account] = error.localizedDescription
        }
    }

    func isPinned(_ repo: Repo) -> Bool {
        pins.contains { $0.id == pinID(repo) }
    }

    func togglePin(_ repo: Repo) {
        if isPinned(repo) {
            pins.removeAll { $0.id == pinID(repo) }
            persist()
            return
        }
        let pin = PinnedRepo(owner: repo.owner.login, name: repo.name, url: repo.htmlUrl, siteURL: repo.homepageURL)
        pins.append(pin)
        persist()
        Task { await resolveSite(for: repo) }
    }

    func unpin(_ pin: PinnedRepo) {
        pins.removeAll { $0.id == pin.id }
        persist()
    }

    func movePins(from source: IndexSet, to destination: Int) {
        pins.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    /// Keeps pinned repos' names, links and deployed URLs current.
    private func refreshSiteURLs(using fetched: [Repo]) async {
        for repo in fetched where isPinned(repo) {
            await resolveSite(for: repo)
        }
    }

    private func resolveSite(for repo: Repo) async {
        let site = await GitHub.siteURL(for: repo)
        guard let index = pins.firstIndex(where: { $0.id == pinID(repo) }) else { return }
        let updated = PinnedRepo(owner: repo.owner.login, name: repo.name, url: repo.htmlUrl, siteURL: site)
        if pins[index] != updated {
            pins[index] = updated
            persist()
        }
    }

    private func pinID(_ repo: Repo) -> String {
        repo.owner.login.lowercased() + "/" + repo.name.lowercased()
    }

    private func persist() {
        PinStore.save(pins)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
