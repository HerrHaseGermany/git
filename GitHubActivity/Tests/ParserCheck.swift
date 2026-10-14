import Foundation

@main struct ParserCheck {
    static func main() async throws {
        precondition(GitHubClient.validate("octocat"))
        precondition(GitHubClient.validate("a"))
        precondition(!GitHubClient.validate("../bad"))
        precondition(!GitHubClient.validate("-invalid"))
        precondition(!GitHubClient.validate("a--b"))
        let fixture = (1...7).reversed().map { "<td data-level=\"\($0 % 5)\" data-date=\"2026-10-0\($0)\">" }.joined()
        let days = try GitHubClient.parse(fixture)
        precondition(days.first?.date == "2026-10-01")
        precondition(days.last?.level == 2)
        do { _ = try GitHubClient.parse("<html>Unavailable</html>"); fatalError("Malformed response accepted") } catch GitHubError.format {}
        do { _ = try GitHubClient.parse(fixture + "<td data-date=\"2026-10-01\" data-level=\"1\">"); fatalError("Duplicate date accepted") } catch GitHubError.format {}
        let counted = (1...7).map { day in
            "<td id=\"day-\(day)\" data-date=\"2026-10-0\(day)\" data-level=\"1\"><tool-tip for=\"day-\(day)\">\(day) contributions on October</tool-tip>"
        }.joined()
        let parsedCounts = try GitHubClient.parse(counted)
        precondition(parsedCounts.map(\.count) == (1...7).map { Optional($0) })
        precondition(ContributionScale.level(.init(date: "2026-10-12", level: 3, count: 12)) == 3)
        precondition(ContributionScale.level(.init(date: "2026-10-13", level: 1, count: 4)) == 1)
        precondition(ContributionScale.level(.init(date: "2026-10-14", level: 0, count: 0)) == 0)
        precondition(ContributionScale.level(.init(date: "2026-10-12", level: 3)) == 3)
        let live = try await GitHubClient.fetch("octocat", useAPI: false)
        precondition(live.days.count >= 365)
        print("PASS: username validation, HTML parsing, ordering, malformed/duplicate rejection, daily counts, GitHub intensity, live GitHub fetch (\(live.days.count) days)")
    }
}
