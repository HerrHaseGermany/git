import AppIntents
import AppKit

struct ProfileIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "GitHub profile"
    static var description = IntentDescription("Enter the GitHub username to display its contributions.")
    @Parameter(title: "Use profile from app", default: true) var useAppProfile: Bool
    @Parameter(title: "GitHub username", default: "") var username: String
    static var parameterSummary: some ParameterSummary {
        Summary { \.$useAppProfile; \.$username }
    }
}

// Runs in the widget process; opening the browser never brings up the host app.
struct OpenProfileIntent: AppIntent {
    static var title: LocalizedStringResource = "Open GitHub profile"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false
    @Parameter(title: "GitHub username") var username: String

    init() { username = "" }
    init(username: String) { self.username = username }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let url = ProfileLink.url(username: username) else { return .result() }
        guard NSWorkspace.shared.open(url) else { throw URLError(.cannotConnectToHost) }
        return .result()
    }
}
