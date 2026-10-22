import SwiftUI
import WidgetKit

@main
struct RepoHubWidgetBundle: WidgetBundle {
    var body: some Widget {
        PinnedReposWidget()
        PinnedSitesWidget()
    }
}

/// What a click on a widget row opens.
enum PinDestination {
    /// The repository on github.com.
    case repository
    /// The deployed website (homepage or GitHub Pages).
    case site
}

private let families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]

struct PinnedReposWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PinnedRepos", provider: PinsProvider()) { entry in
            PinsWidgetView(entry: entry, destination: .repository)
        }
        .configurationDisplayName("Pinned Repos")
        .description("Your pinned repositories. Click one to open it on GitHub.")
        .supportedFamilies(families)
    }
}

struct PinnedSitesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PinnedSites", provider: PinsProvider()) { entry in
            PinsWidgetView(entry: entry, destination: .site)
        }
        .configurationDisplayName("Pinned Sites")
        .description("The live websites of your pinned repositories, from GitHub Pages or a custom URL.")
        .supportedFamilies(families)
    }
}

// MARK: - Timeline

struct PinsEntry: TimelineEntry {
    let date: Date
    let pins: [PinnedRepo]
}

struct PinsProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinsEntry {
        PinsEntry(date: .now, pins: PinnedRepo.samples)
    }

    func getSnapshot(in context: Context, completion: @escaping (PinsEntry) -> Void) {
        let pins = PinStore.load()
        completion(PinsEntry(date: .now, pins: context.isPreview && pins.isEmpty ? PinnedRepo.samples : pins))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PinsEntry>) -> Void) {
        // The app reloads timelines whenever pins change.
        completion(Timeline(entries: [PinsEntry(date: .now, pins: PinStore.load())], policy: .never))
    }
}

// MARK: - Views

struct PinsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PinsEntry
    let destination: PinDestination

    private struct Item: Identifiable {
        let pin: PinnedRepo
        let target: URL
        var id: String { pin.id }
    }

    private var items: [Item] {
        entry.pins.compactMap { pin in
            switch destination {
            case .repository: return Item(pin: pin, target: pin.url)
            case .site: return pin.siteURL.map { Item(pin: pin, target: $0) }
            }
        }
    }

    private var columns: Int {
        switch family {
        case .systemMedium, .systemExtraLarge: return 2
        default: return 1
        }
    }

    private var rows: Int {
        switch family {
        case .systemSmall, .systemMedium: return 4
        default: return 9
        }
    }

    private var title: String { destination == .site ? "Sites" : "Repos" }
    private var symbol: String { destination == .site ? "globe" : "pin.fill" }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            header
            if items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { GlassBackground() }
        .widgetURL(URL(string: "\(PinStore.scheme)://app"))
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tint)
                .widgetAccentable()
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if items.count > columns * rows {
                Text("+\(items.count - columns * rows)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 2)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer(minLength: 0)
            Text(destination == .site ? "No live sites pinned" : "No pinned repos")
                .font(.system(size: 13, weight: .semibold))
            Text(destination == .site
                 ? "Pin repos with GitHub Pages or a homepage URL in RepoHub."
                 : "Open RepoHub and pin repositories.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private var list: some View {
        let visible = Array(items.prefix(columns * rows))
        let perColumn = Int((Double(visible.count) / Double(columns)).rounded(.up))
        return HStack(alignment: .top, spacing: 6) {
            ForEach(0..<columns, id: \.self) { column in
                let slice = visible.dropFirst(column * perColumn).prefix(perColumn)
                VStack(spacing: 3) {
                    ForEach(Array(slice)) { item in
                        Link(destination: PinStore.widgetLink(to: item.target)) {
                            NameRow(name: item.pin.name, compact: family == .systemSmall)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct NameRow: View {
    let name: String
    let compact: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(.tint)
                .frame(width: 5, height: 5)
                .widgetAccentable()
            Text(name)
                .font(.system(size: compact ? 12 : 13, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, compact ? 4 : 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
    }
}

/// Liquid Glass on macOS 26 and later, translucent material on earlier systems.
private struct GlassBackground: View {
    var body: some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular, in: Rectangle())
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
        #else
        Rectangle().fill(.ultraThinMaterial)
        #endif
    }
}

#Preview(as: .systemMedium) {
    PinnedSitesWidget()
} timeline: {
    PinsEntry(date: .now, pins: PinnedRepo.samples)
}
