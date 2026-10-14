// Reads an already-authorized credential from stdin; never logs the credential.
import Foundation
import Security

let token = FileHandle.standardInput.readDataToEndOfFile()
guard !token.isEmpty else { fatalError("No GitHub credential supplied") }
let paths = [
    "/Applications/GitHub Activity.app/Contents/MacOS/GitHub Activity",
    "/Applications/GitHub Activity.app/Contents/PlugIns/GitHubActivityWidget.appex/Contents/MacOS/GitHubActivityWidget"
]
var trusted: [SecTrustedApplication] = []
for path in paths {
    var app: SecTrustedApplication?
    let status = SecTrustedApplicationCreateFromPath(path, &app)
    guard status == errSecSuccess, let app else { fatalError("Could not authorize installed app: \(status)") }
    trusted.append(app)
}
var access: SecAccess?
guard SecAccessCreate("GitHub Activity API connection" as CFString, trusted as CFArray, &access) == errSecSuccess else { fatalError("Could not create keychain access") }
let query: [String: Any] = [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:"de.raudzis.GitHubActivity.github-api", kSecAttrAccount as String:"github.com"]
var add = query
add[kSecAttrLabel as String] = "GitHub Activity – GitHub API"
add[kSecAttrAccess as String] = access!
add[kSecValueData as String] = token
let status = SecItemAdd(add as CFDictionary, nil)
guard status == errSecSuccess else { fatalError("Keychain connection could not be saved: \(status)") }
print("GitHub connection saved securely for the installed app and widget.")
