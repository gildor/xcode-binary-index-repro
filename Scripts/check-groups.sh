#!/bin/bash
# Usage: [DEPS="<dep.xcframework> ..."] check-groups.sh <xcframework> <ModuleName> [group]
# DEPS: companion xcframeworks the module imports (e.g. the C framework a Swift framework imports).
# Asks SourceKit (the service Xcode uses) which module groups a binary Swift framework ships, and,
# with a group name, which types that group's generated interface contains.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCF="$(cd "$1" && pwd)"; MOD="$2"; GROUP="${3:-}"
SLICE=$(ls -d "$XCF"/ios-*-simulator | head -1)
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
FARGS="\"-F\", \"$SLICE\""
for DEP in ${DEPS:-}; do FARGS="$FARGS, \"-F\", \"$(ls -d "$(cd "$DEP" && pwd)"/ios-*-simulator | head -1)\""; done
ARGS="[\"-sdk\", \"$SDK\", \"-target\", \"arm64-apple-ios16.0-simulator\", $FARGS, \"-module-cache-path\", \"$TMP/mc\"]"
echo "{ key.request: source.request.module.groups, key.modulename: \"$MOD\", key.compilerargs: $ARGS }" > "$TMP/groups.yaml"
echo "groups:"; python3 "$ROOT/Tools/sk.py" "$TMP/groups.yaml" | grep -oE '"[^"]+"' | grep -v '^"key\.' | sed 's/^/  /'
if [ -n "$GROUP" ]; then
  echo "{ key.request: source.request.editor.open.interface, key.name: \"g\", key.modulename: \"$MOD\", key.groupname: \"$GROUP\", key.compilerargs: $ARGS }" > "$TMP/iface.yaml"
  echo "types in group '$GROUP':"
  python3 "$ROOT/Tools/sk.py" "$TMP/iface.yaml" | grep -oE '(class|struct|protocol|enum|actor) [A-Za-z_][A-Za-z0-9_]*' | sort -u | sed 's/^/  /'
fi
