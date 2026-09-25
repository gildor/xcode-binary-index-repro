#!/bin/bash
# Builds every host app with index-while-building on, each into its own DerivedData.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Honors DEVELOPER_DIR; outputs go to .build/<xcode build>/dd-<App>.
XC=$(xcodebuild -version | awk '/Build version/{print $3}')
echo "Xcode $XC"
for APP in XcodeSource XcodeBinary XcodeDirect TuistBinary; do
  if [ "$APP" = TuistBinary ]; then CONTAINER=(-workspace "$ROOT/Apps/$APP/$APP.xcworkspace")
  else CONTAINER=(-project "$ROOT/Apps/$APP/$APP.xcodeproj"); fi
  # Clean build: index-while-building only records files it recompiles.
  rm -rf "$ROOT/.build/$XC/dd-$APP"
  xcodebuild build -quiet "${CONTAINER[@]}" -scheme "$APP" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$ROOT/.build/$XC/dd-$APP" \
    COMPILER_INDEX_STORE_ENABLE=YES 2>&1 | grep -E 'error:|BUILD' | head -5
  echo "$APP: exit ${PIPESTATUS[0]}"
done
