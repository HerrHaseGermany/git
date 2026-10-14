import Foundation
import Security
import LocalAuthentication
import OSLog

enum GitHubTokenStore {
    static let service = "de.raudzis.GitHubActivity.github-api"
    static func read() throws -> String? {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "github.com",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw GitHubError.authentication }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GitHubAPI {
    struct Envelope: Decodable {
        struct Payload: Decodable {
            struct User: Decodable {
                struct Collection: Decodable {
                    struct Calendar: Decodable {
                        struct Week: Decodable {
                            struct Day: Decodable {
                                let date: String
                                let contributionCount: Int
                                let contributionLevel: String
                            }
                            let contributionDays: [Day]
                        }
                        let weeks: [Week]
                    }
                    let contributionCalendar: Calendar
                }
                let contributionsCollection: Collection
            }
            let user: User?
            let viewer: User?
        }
        let data: Payload?
    }
    static func decode(_ data: Data, username: String) throws -> ContributionSnapshot {
        let response = try JSONDecoder().decode(Envelope.self, from: data)
        guard let user = response.data?.user ?? response.data?.viewer else { throw GitHubError.response }
        let levels = ["NONE": 0, "FIRST_QUARTILE": 1, "SECOND_QUARTILE": 2, "THIRD_QUARTILE": 3, "FOURTH_QUARTILE": 4]
        let days = try user.contributionsCollection.contributionCalendar.weeks.flatMap(\.contributionDays).map { day in
            guard let level = levels[day.contributionLevel], day.contributionCount >= 0 else { throw GitHubError.format }
            return ContributionDay(date: day.date, level: level, count: day.contributionCount, apiLevel: true)
        }.sorted { $0.date < $1.date }
        guard days.count >= 7, Set(days.map(\.date)).count == days.count else { throw GitHubError.format }
        return .init(username: username, fetchedAt: Date(), days: days)
    }
    static func fetch(username: String, token: String) async throws -> ContributionSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = calendar.startOfDay(for: Date())
        let sunday = calendar.date(byAdding: .day, value: -(calendar.component(.weekday, from: today) - 1), to: today)!
        let from = calendar.date(byAdding: .day, value: -15 * 7, to: sunday)!
        let formatter = ISO8601DateFormatter()
        let query = "query($login:String!, $from:DateTime!, $to:DateTime!) { user(login:$login) { contributionsCollection(from:$from,to:$to) { contributionCalendar { weeks { contributionDays { date contributionCount contributionLevel } } } } } }"
        let variables = ["login": username, "from": formatter.string(from: from), "to": formatter.string(from: Date())]
        var request = URLRequest(url: URL(string: "https://api.github.com/graphql")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("GitHubActivity-macOS", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query, "variables": variables])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw GitHubError.response }
        let snapshot = try decode(data, username: username)
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "GitHubActivity", category: "GitHubAPI")
            .info("Authenticated GitHub calendar loaded: \(snapshot.days.count, privacy: .public) days")
        return snapshot
    }
}
