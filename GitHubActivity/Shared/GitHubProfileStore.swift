import Foundation
import Security
import LocalAuthentication

enum GitHubProfileStore {
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "de.raudzis.GitHubActivity.profile",
         kSecAttrAccount as String: "default"]
    }
    static func read() throws -> String? {
        var request = query
        let context = LAContext()
        context.interactionNotAllowed = true
        request[kSecUseAuthenticationContext as String] = context
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let username = String(data: data, encoding: .utf8) else { throw GitHubError.authentication }
        return GitHubClient.validate(username) ? username : nil
    }
    static func write(_ username: String) throws {
        guard GitHubClient.validate(username) else { throw GitHubError.username }
        let data = Data(username.utf8)
        let updated = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updated == errSecSuccess { return }
        guard updated == errSecItemNotFound else { throw GitHubError.authentication }
        guard let executable = Bundle.main.executableURL, let plugins = Bundle.main.builtInPlugInsURL else { throw GitHubError.authentication }
        let paths = [executable.path, plugins.appendingPathComponent("GitHubActivityWidget.appex/Contents/MacOS/GitHubActivityWidget").path]
        var trusted: [SecTrustedApplication] = []
        for path in paths {
            var app: SecTrustedApplication?
            guard SecTrustedApplicationCreateFromPath(path, &app) == errSecSuccess, let app else { throw GitHubError.authentication }
            trusted.append(app)
        }
        var access: SecAccess?
        guard SecAccessCreate("GitHub Activity profile" as CFString, trusted as CFArray, &access) == errSecSuccess else { throw GitHubError.authentication }
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccess as String] = access!
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw GitHubError.authentication }
    }
}
