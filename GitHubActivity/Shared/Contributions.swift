import Foundation

struct ContributionDay: Codable, Sendable {
    let date: String
    let level: Int
    let count: Int?
    let apiLevel: Bool?
    init(date: String, level: Int, count: Int? = nil, apiLevel: Bool? = nil) {
        self.date = date
        self.level = level
        self.count = count
        self.apiLevel = apiLevel
    }
}

struct ContributionSnapshot: Codable, Sendable {
    let username: String
    let fetchedAt: Date
    let days: [ContributionDay]
}

enum GitHubError: LocalizedError {
    case username, response, format, authentication
    var errorDescription: String? {
        switch self {
        case .authentication: NSLocalizedString("GitHub connection is unavailable. Reconnect in the app.", comment: "GitHub error")
        case .username: NSLocalizedString("Please enter a valid GitHub username.", comment: "GitHub error")
        case .response: NSLocalizedString("GitHub is unavailable or the profile does not exist.", comment: "GitHub error")
        case .format: NSLocalizedString("The contribution calendar could not be read.", comment: "GitHub error")
        }
    }
}

enum GitHubClient {
    static func validate(_ username: String) -> Bool {
        username.range(of: #"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$"#, options: .regularExpression) != nil && !username.contains("--")
    }

    static func parse(_ html: String) throws -> [ContributionDay] {
        let cells = try NSRegularExpression(pattern: #"<td\b[^>]*>"#)
        let datePattern = try NSRegularExpression(pattern: #"data-date="(\d{4}-\d{2}-\d{2})""#)
        let levelPattern = try NSRegularExpression(pattern: #"data-level="([0-4])""#)
        let tooltipPattern = try NSRegularExpression(pattern: #"<tool-tip\b[^>]*for="([^"]+)"[^>]*>([^<]*)</tool-tip>"#)
        let idPattern = try NSRegularExpression(pattern: #"\bid="([^"]+)""#)
        let countPattern = try NSRegularExpression(pattern: #"^([0-9,]+) contributions? on "#)
        let source = html as NSString
        var counts: [String: Int] = [:]
        for tooltip in tooltipPattern.matches(in: html, range: NSRange(location: 0, length: source.length)) {
            let id = source.substring(with: tooltip.range(at: 1))
            let label = source.substring(with: tooltip.range(at: 2))
            if label.hasPrefix("No contributions") { counts[id] = 0 }
            else if let match = countPattern.firstMatch(in: label, range: NSRange(location: 0, length: (label as NSString).length)) {
                counts[id] = Int((label as NSString).substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: ""))
            }
        }
        var days: [ContributionDay] = []
        for cell in cells.matches(in: html, range: NSRange(location: 0, length: source.length)) {
            let tag = source.substring(with: cell.range)
            let range = NSRange(location: 0, length: (tag as NSString).length)
            if let date = datePattern.firstMatch(in: tag, range: range),
               let level = levelPattern.firstMatch(in: tag, range: range),
               let value = Int((tag as NSString).substring(with: level.range(at: 1))) {
                let id = idPattern.firstMatch(in: tag, range: range).map { (tag as NSString).substring(with: $0.range(at: 1)) }
                days.append(.init(date: (tag as NSString).substring(with: date.range(at: 1)), level: value, count: id.flatMap { counts[$0] }))
            }
        }
        guard days.count >= 7, Set(days.map(\.date)).count == days.count else { throw GitHubError.format }
        return days.sorted { $0.date < $1.date }
    }

    static func fetch(_ input: String, useAPI: Bool = true) async throws -> ContributionSnapshot {
        let username = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validate(username) else { throw GitHubError.username }
        if useAPI, let token = try GitHubTokenStore.read() {
            return try await GitHubAPI.fetch(username: username, token: token)
        }
        var request = URLRequest(url: URL(string: "https://github.com/users/\(username)/contributions")!)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("GitHubActivity-macOS/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw GitHubError.response }
        guard let html = String(data: data, encoding: .utf8) else { throw GitHubError.format }
        return .init(username: username, fetchedAt: Date(), days: try parse(html))
    }
}

// Widget-local cache: an outage retains the last successful graph for this profile.
enum SnapshotCache {
    static func url(_ username: String) -> URL? {
        guard GitHubClient.validate(username), let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = root.appendingPathComponent("GitHubActivity", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(username.lowercased()).appendingPathExtension("json")
    }
    static func read(_ username: String) -> ContributionSnapshot? {
        guard let url = url(username), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ContributionSnapshot.self, from: data)
    }
    static func write(_ snapshot: ContributionSnapshot) {
        guard let url = url(snapshot.username), let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

// Preserve the contribution level provided by GitHub.
enum ContributionScale {
    static func level(_ day: ContributionDay) -> Int {
        min(4, max(0, day.level))
    }
}
