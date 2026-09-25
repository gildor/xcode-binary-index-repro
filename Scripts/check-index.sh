#!/bin/bash
# Usage: check-index.sh <DataStore dir>... — reports which framework types have a definition in the index.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYMS=(SwiftKitPlaybackController SwiftKitTrackModel SwiftKitRendering SwiftKitMixerConsole SwiftKitTempoMap SwiftKitWaveformRenderer OBJKAudioMixer OBJKMixerMode EngineSwiftMixHandler EngineCMixHandle engine_c_make_mix)
for DS in "$@"; do echo "=== $DS"; "$ROOT/Tools/indexdump" "$DS" "${SYMS[@]}"; done
