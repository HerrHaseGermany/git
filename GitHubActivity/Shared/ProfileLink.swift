import Foundation

enum ProfileLink {
    static func url(username: String) -> URL? {
        guard GitHubClient.validate(username) else { return nil }
        return URL(string: "https://github.com/\(username)")
    }
}
