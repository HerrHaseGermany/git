import SwiftUI
import WidgetKit
import AppIntents

struct ActivityEntry: TimelineEntry {
    let date: Date
    let username: String
    let snapshot: ContributionSnapshot?
    let message: String?
}

struct ActivityProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ActivityEntry {
        .init(date: Date(), username: "", snapshot: nil, message: String(localized: "Enter a GitHub username"))
    }
    func snapshot(for configuration: ProfileIntent, in context: Context) async -> ActivityEntry {
        await load(configuration)
    }
    func timeline(for configuration: ProfileIntent, in context: Context) async -> Timeline<ActivityEntry> {
        let entry = await load(configuration)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
    }
    func load(_ configuration: ProfileIntent) async -> ActivityEntry {
        do {
            let username = configuration.useAppProfile ? (try GitHubProfileStore.read() ?? configuration.username) : configuration.username
            return await loadUsername(username)
        } catch {
            return .init(date: Date(), username: "", snapshot: nil, message: error.localizedDescription)
        }
    }
    func loadUsername(_ input: String) async -> ActivityEntry {
        let username = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return .init(date: Date(), username: "", snapshot: nil, message: String(localized: "Enter a GitHub username")) }
        do {
            let snapshot = try await GitHubClient.fetch(username)
            SnapshotCache.write(snapshot)
            return .init(date: Date(), username: username, snapshot: snapshot, message: nil)
        } catch {
            return .init(date: Date(), username: username, snapshot: SnapshotCache.read(username), message: error.localizedDescription)
        }
    }
}

struct ActivityWidgetView: View {
    let entry: ActivityEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    var body: some View {
        Button(intent: OpenProfileIntent(username: entry.username)) {
            content
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if renderingMode == .fullColor {
                ContainerRelativeShape().fill(WidgetAppearance.background)
                    .overlay {
                        ContainerRelativeShape()
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75)
                    }
            }
        }
        .containerBackground(for: .widget) {
            // macOS can remove this layer; the color-mode card above stays visible.
            Color.clear
        }
    }

    private var content: some View {
        Group {
            if let snapshot = entry.snapshot {
                HeatmapView(days: snapshot.days, columns: family == .systemSmall ? 7 : 16)
                    .overlay(alignment: .bottomTrailing) {
                        if entry.message != nil {
                            Image(systemName: "wifi.slash").font(.caption2).foregroundStyle(.yellow).padding(2)
                        }
                    }
                    .accessibilityLabel(Text("GitHub activity for \(entry.username)"))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill").foregroundStyle(.green)
                    Text(entry.message ?? String(localized: "Loading GitHub…")).font(.caption).multilineTextAlignment(.center)
                    if entry.username.isEmpty { Text("Right-click → Edit Widget").font(.caption2).foregroundStyle(.secondary) }
                }.padding(8)
            }
        }

    }
}

@main
struct GitHubActivityWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "GitHubActivity", intent: ProfileIntent.self, provider: ActivityProvider()) { entry in
            ActivityWidgetView(entry: entry)
        }
        .configurationDisplayName("GitHub Activity")
        .description("Your GitHub contributions. Directly on your Mac, without an iPhone.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
