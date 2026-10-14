import SwiftUI
import WidgetKit

@main
struct GitHubActivityApp: App {
    var body: some Scene {
        WindowGroup("GitHub Activity", id: "main") { ContentView() }
            .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @AppStorage("username") private var username = ""
    @State private var snapshot: ContributionSnapshot?
    @State private var message: String?
    @State private var loading = false
    @FocusState private var usernameFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image("AppIcon").resizable().scaledToFit().frame(width: 44, height: 44)
                VStack(alignment: .leading) {
                    Text("GitHub Activity").font(.title.bold())
                    Text("Your contributions. Directly on your Mac.").foregroundStyle(.secondary)
                }
            }
            HStack {
                TextField("GitHub username", text: $username)
                    .textFieldStyle(.plain)
                    .focused($usernameFocused)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(usernameFocused ? Color.accentColor : Color.secondary.opacity(0.45), lineWidth: usernameFocused ? 2 : 1)
                    }
                    .onSubmit { Task { await refresh() } }
                Button { Task { await refresh() } } label: {
                    Text(loading ? LocalizedStringKey("Loading…") : LocalizedStringKey("Load"))
                }.disabled(loading)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(WidgetAppearance.background)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.24), .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75)
                    }
                if let snapshot {
                    HeatmapView(days: snapshot.days).padding(16)
                } else {
                    Text("Enter a username to load the calendar").foregroundStyle(.secondary)
                }
            }.frame(height: 250)
            if let message { Text(message).font(.callout).foregroundStyle(.orange) }
            if let snapshot {
                Text("@\(snapshot.username) · Updated: \(snapshot.fetchedAt.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
            }
            if snapshot?.days.first?.apiLevel == true {
                Label("Connected to GitHub API", systemImage: "checkmark.shield.fill")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            Text("Add a widget").font(.headline)
            Text("Load a GitHub profile here; your widgets use it automatically.\nTo add a widget: right-click the desktop → Edit Widgets → GitHub Activity.")
                .lineSpacing(5).fixedSize(horizontal: false, vertical: true)
            Group {
                if snapshot?.days.first?.apiLevel == true {
                    Text("GitHub API · Connection stored in macOS Keychain\nThe widget requests hourly updates; macOS decides when to refresh.")
                } else {
                    Text("Public GitHub contribution calendar · No token required\nThe widget requests hourly updates; macOS decides when to refresh.")
                }
            }.font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .padding(28).frame(width: 560)
        .task { if !username.isEmpty { await refresh() } }

    }
    @MainActor private func refresh() async {
        loading = true
        defer { loading = false }
        do {
            snapshot = try await GitHubClient.fetch(username)
            if let snapshot { try GitHubProfileStore.write(snapshot.username) }
            message = nil
            WidgetCenter.shared.reloadAllTimelines()
        } catch { message = error.localizedDescription }
    }
}
