#!/bin/zsh
set -eu
build_dir="${GITHUB_ACTIVITY_BUILD_DIR:-/tmp/GitHubActivity-build}"
source_app="$build_dir/Build/Products/Release/GitHub Activity.app"
target_app="/Applications/GitHub Activity.app"
lsregister_bin="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
[[ -d "$source_app" ]] || { print -u2 'Build first: ./scripts/build.sh'; exit 1; }
/usr/bin/codesign --verify --deep --strict "$source_app"
# A suspended old extension otherwise keeps the old intent parameter definitions.
/usr/bin/pkill -x GitHubActivityWidget || true
/usr/bin/pkill -x 'GitHub Activity' || true
/usr/bin/ditto "$source_app" "$target_app"
/usr/bin/codesign --verify --deep --strict "$target_app"
"$lsregister_bin" -u "$source_app"
/usr/bin/touch "$target_app"
"$lsregister_bin" -f "$target_app"
/usr/bin/pluginkit -a "$target_app/Contents/PlugIns/GitHubActivityWidget.appex"
# Do not launch the preview after installation. Widgets run independently.
