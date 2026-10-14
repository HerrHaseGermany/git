#!/bin/zsh
set -eu
project_dir="${0:A:h:h}"
build_dir="${GITHUB_ACTIVITY_BUILD_DIR:-/tmp/GitHubActivity-build}"
# App Intents validates the TeamIdentifier, so use a development certificate.
signing_identity="${GITHUB_ACTIVITY_SIGNING_IDENTITY:-$(/usr/bin/security find-identity -v -p codesigning | /usr/bin/sed -n 's/.*) \([A-F0-9]*\) "Apple Development:.*$/\1/p' | /usr/bin/head -1)}"
[[ -n "$signing_identity" ]] || { print -u2 'A valid Apple Development certificate is required for widget configuration.'; exit 1; }
swift "$project_dir/scripts/generate_icon.swift" "$project_dir"
xcodebuild -project "$project_dir/GitHubActivity.xcodeproj" -scheme GitHubActivity -configuration Release -derivedDataPath "$build_dir" CODE_SIGN_IDENTITY="$signing_identity" build
print "App: $build_dir/Build/Products/Release/GitHub Activity.app"
