import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: RepoModel
    @State private var account: Account = .lj
    @State private var query = ""

    private var filtered: [Repo] {
        let repos = (model.repos[account] ?? []).sorted { ($0.pushedAt ?? .distantPast) > ($1.pushedAt ?? .distantPast) }
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return repos }
        return repos.filter {
            $0.name.localizedCaseInsensitiveContains(q) || ($0.description ?? "").localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        List {
            Section {
                if model.pins.isEmpty {
                    Text("Pin repositories below to show them in the RepoHub widgets.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.pins) { pin in
                        PinRow(pin: pin) { model.unpin(pin) }
                    }
                    .onMove { model.movePins(from: $0, to: $1) }
                }
            } header: {
                Text("Pinned · shown in widgets")
            } footer: {
                if !model.pins.isEmpty {
                    Text("Drag to reorder. “Pinned Repos” opens the repository; “Pinned Sites” opens the deployed website.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(account.login) {
                if let error = model.errors[account] {
                    Text(error).foregroundStyle(.red)
                } else if model.repos[account] == nil {
                    HStack { Spacer(); ProgressView().controlSize(.small); Spacer() }
                } else if filtered.isEmpty {
                    Text(query.isEmpty ? "No public repositories found." : "No repositories match “\(query)”.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filtered) { repo in
                        RepoRow(repo: repo, pinned: model.isPinned(repo)) { model.togglePin(repo) }
                    }
                }
            }
        }
        .searchable(text: $query, placement: .toolbar, prompt: "Search repositories")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Account", selection: $account) {
                    ForEach(Account.allCases) { Text($0.login).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            ToolbarItem {
                Button {
                    Task { await model.load(account, force: true) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(model.loading.contains(account))
            }
        }
        .task(id: account) { await model.load(account) }
    }
}

private struct PinRow: View {
    let pin: PinnedRepo
    let unpin: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "pin.fill").foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(pin.name).font(.system(.body, design: .monospaced).weight(.medium))
                Text(pin.siteURL?.host() ?? "no deployed site")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let site = pin.siteURL {
                Button { NSWorkspace.shared.open(site) } label: { Image(systemName: "globe") }
                    .buttonStyle(.borderless)
                    .help("Open \(site.absoluteString)")
            }
            Button { NSWorkspace.shared.open(pin.url) } label: { Image(systemName: "arrow.up.right.square") }
                .buttonStyle(.borderless)
                .help("Open repository on GitHub")
            Button(action: unpin) { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                .buttonStyle(.borderless)
                .help("Unpin")
        }
        .padding(.vertical, 2)
    }
}

private struct RepoRow: View {
    let repo: Repo
    let pinned: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(repo.name).font(.system(.body, design: .monospaced).weight(.medium))
                    if repo.fork { TagLabel("fork") }
                    if repo.archived { TagLabel("archived") }
                    if repo.homepageURL != nil || repo.hasPages { TagLabel("live") }
                }
                if let description = repo.description, !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button(action: toggle) {
                Image(systemName: pinned ? "pin.fill" : "pin")
                    .foregroundStyle(pinned ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            .buttonStyle(.borderless)
            .help(pinned ? "Unpin" : "Pin to widgets")
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { NSWorkspace.shared.open(repo.htmlUrl) }
    }
}

private struct TagLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .overlay(Capsule().strokeBorder(.quaternary))
    }
}
