#!/bin/bash
# Summary table of which types each app's index defines, for every Xcode build under .build/.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for DS in "$ROOT"/.build/*/dd-*/Index.noindex/DataStore; do
  label=$(echo "$DS" | sed -E 's|.*/\.build/([^/]+)/dd-([^/]+)/.*|\1 \2|')
  echo "### $label"; "$ROOT/Scripts/check-index.sh" "$DS" | sed -n '/-- summary/,$p' | tail -n +2
done
