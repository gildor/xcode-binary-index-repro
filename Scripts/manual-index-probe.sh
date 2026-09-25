#!/bin/bash
# Compiles Apps/Shared/ReproApp.swift directly with swiftc against the binary xcframework slices,
# varying one flag at a time, and reports whether binary Swift types get indexed.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
E=.build/manual; SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
B=Packages/BinaryPkg/Binaries; S=ios-arm64_x86_64-simulator
F=(); FS=()
for n in SwiftKit ObjCKit EngineSwift EngineC; do F+=(-F "$B/$n.xcframework/$S"); FS+=(-Fsystem "$B/$n.xcframework/$S"); done
run() {
  local label=$1; shift
  rm -rf "$E/$label"; mkdir -p "$E/$label"
  xcrun swiftc -c -o "$E/$label/out.o" -sdk "$SDK" -target arm64-apple-ios16.0-simulator -parse-as-library \
    -module-name ReproManual -module-cache-path "$E/$label/mc" -index-store-path "$E/$label/store" \
    "$@" Apps/Shared/ReproApp.swift 2>&1 | grep -E 'error' | head -3
  printf '%-26s ' "$label"
  ./Tools/indexdump "$E/$label/store" SwiftKitPlaybackController EngineSwiftMixHandler OBJKAudioMixer \
    | sed -n '/summary/,$p' | tail -3 | awk '{printf "%s=%s  ", $1, $2}'; echo
}
run plain-F "${F[@]}"
run Fsystem "${FS[@]}"
run explicit "${F[@]}" -explicit-module-build
run F+index-sys "${F[@]}" -Xfrontend -index-system-modules
run Fsystem+index-sys "${FS[@]}" -Xfrontend -index-system-modules
