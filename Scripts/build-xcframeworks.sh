#!/bin/bash
# Builds Binaries/<Name>.xcframework (device + simulator) for every Vendor framework.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/.build/vendor"
OUT="$ROOT/Packages/BinaryPkg/Binaries"
cd "$ROOT/Vendor" && xcodegen generate --quiet
rm -rf "$BUILD" "$OUT" && mkdir -p "$BUILD" "$OUT"
# SwiftKit gets one module group per source file, so Jump to Definition can show a per-class
# generated interface instead of the whole module (groups are stored in the shipped .swiftdoc).
GROUP_INFO="$BUILD/SwiftKit-group_info.json"
python3 - "$ROOT/Packages/SourcePkg/Sources/SwiftKit" "$GROUP_INFO" <<'PY'
import json, sys, pathlib
files = sorted(pathlib.Path(sys.argv[1]).rglob("*.swift"))
json.dump({f.stem: [f.name] for f in files}, open(sys.argv[2], "w"), indent=2)
PY
for FW in EngineC SwiftKit ObjCKit EngineSwift; do
  EXTRA=()
  [ "$FW" = SwiftKit ] && EXTRA=(OTHER_SWIFT_FLAGS="-Xfrontend -group-info-path -Xfrontend $GROUP_INFO")
  for SDK in iphoneos iphonesimulator; do
    xcodebuild archive "${EXTRA[@]}" -quiet -project "$ROOT/Vendor/Vendor.xcodeproj" -scheme "$FW" \
      -destination "generic/platform=$([ $SDK = iphoneos ] && echo iOS || echo 'iOS Simulator')" \
      -archivePath "$BUILD/$FW-$SDK.xcarchive" -derivedDataPath "$BUILD/dd"
  done
  xcodebuild -create-xcframework \
    -framework "$BUILD/$FW-iphoneos.xcarchive/Products/Library/Frameworks/$FW.framework" \
    -framework "$BUILD/$FW-iphonesimulator.xcarchive/Products/Library/Frameworks/$FW.framework" \
    -output "$OUT/$FW.xcframework"
done
