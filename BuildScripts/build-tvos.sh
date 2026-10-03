#!/bin/bash
set -euo pipefail

# Unsigned device build. Install from Xcode with your own signing Team.
task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$task_root"
configuration="${1:-Debug}"
case "$configuration" in
  Debug|Release) ;;
  *) echo "Usage: bash BuildScripts/build-tvos.sh [Debug|Release]" >&2; exit 2 ;;
esac
if [[ "$(uname -s)" != Darwin ]]; then
  echo "tvOS builds require macOS and full Xcode. See docs/MAC_HANDOFF.md." >&2
  exit 1
fi
if ! xcrun --sdk appletvos --show-sdk-path >/dev/null; then
  echo "Select full Xcode in Xcode > Settings > Locations > Command Line Tools." >&2
  exit 1
fi
xcode_major="$(xcodebuild -version | awk '/^Xcode / {split($2, parts, "."); print parts[1]}')"
if [[ ! "$xcode_major" =~ ^[0-9]+$ ]] || (( xcode_major < 26 )); then
  echo "This VoidLink baseline uses SDK 26 APIs and requires Xcode 26 or later." >&2
  exit 1
fi
if git submodule status --recursive | grep -qE '^[-+U]'; then
  echo "Initialize pinned dependencies: git submodule update --init --recursive" >&2
  exit 1
fi

mkdir -p build
plutil -lint VoidLink.xcodeproj/project.pbxproj 'VoidLink TV/Info.plist'
xcodebuild -resolvePackageDependencies \
  -project VoidLink.xcodeproj -scheme 'Moonlight Plus TV' \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -onlyUsePackageVersionsFromResolvedFile
xcodebuild build \
  -project VoidLink.xcodeproj -scheme 'Moonlight Plus TV' \
  -configuration "$configuration" -sdk appletvos \
  -destination 'generic/platform=tvOS' \
  -derivedDataPath build/DerivedData \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -disableAutomaticPackageResolution \
  -resultBundlePath "build/tvos-${configuration}-$(date +%Y%m%d-%H%M%S).xcresult" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  2>&1 | tee "build/tvos-${configuration}.log"
