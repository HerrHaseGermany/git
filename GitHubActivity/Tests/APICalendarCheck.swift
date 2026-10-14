import Foundation
@main struct APICalendarCheck {
    static func main() throws {
        let rows: [[String: Any]] = (1...7).map { index in
            ["date": "2026-10-0\(index)", "contributionCount": index, "contributionLevel": index < 4 ? "FIRST_QUARTILE" : "FOURTH_QUARTILE"]
        }
        func payload(_ rows: [[String: Any]]) throws -> Data {
            try JSONSerialization.data(withJSONObject: ["data": ["user": ["contributionsCollection": ["contributionCalendar": ["weeks": [["contributionDays": rows]]]]]]])
        }
        let calendar = try GitHubAPI.decode(payload(rows), username: "octocat")
        precondition(calendar.days.count == 7)
        precondition(calendar.days.allSatisfy { $0.apiLevel == true })
        precondition(calendar.days.map(\.count) == (1...7).map { Optional($0) })
        precondition(calendar.days.map { ContributionScale.level($0) } == [1, 1, 1, 4, 4, 4, 4])
        precondition(ContributionScale.level(.init(date: "2026-10-08", level: 4, count: 0, apiLevel: true)) == 4)
        for level in 0...4 {
            precondition(ContributionScale.level(.init(date: "2026-10-08", level: level, count: 100, apiLevel: true)) == level)
        }
        do { _ = try GitHubAPI.decode(payload(rows + [rows[0]]), username: "octocat"); fatalError("Duplicate accepted") } catch GitHubError.format {}
        do { _ = try GitHubAPI.decode(Data("{\"data\":{\"user\":null}}".utf8), username: "missing"); fatalError("Missing user accepted") } catch GitHubError.response {}
        var invalid = rows
        invalid[0]["contributionLevel"] = "UNEXPECTED"
        do { _ = try GitHubAPI.decode(payload(invalid), username: "octocat"); fatalError("Unknown level accepted") } catch GitHubError.format {}
        print("PASS: official API decoding, exact daily counts, authoritative API levels, duplicate/invalid response rejection")
    }
}
