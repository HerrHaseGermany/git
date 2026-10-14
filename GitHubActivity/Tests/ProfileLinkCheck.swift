import Foundation

@main struct ProfileLinkCheck {
    static func main() {
        precondition(ProfileLink.url(username: "HerrHaseGermany")?.absoluteString == "https://github.com/HerrHaseGermany")
        for name in ["../bad", "a/b", "a?next=bad", "https://example.com", "a--b", ""] {
            precondition(ProfileLink.url(username: name) == nil)
        }
        precondition(!OpenProfileIntent.openAppWhenRun)
        print("PASS: direct profile URL, invalid input rejection, background intent")
    }
}
