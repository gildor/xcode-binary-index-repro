# Xcode binary vs source framework indexing repro

The same four frameworks, consumed four ways, to reproduce "Open Quickly can't find classes from
binary frameworks".

| Framework | Language | Mirrors |
|---|---|---|
| `SwiftKit` | Swift, library evolution (`.swiftinterface`) | any Swift xcframework |
| `ObjCKit` | Objective-C | ObjC SDKs |
| `EngineSwift` + `EngineC` | Swift surface over a separate C framework | Swift SDKs layered on a C core |

| App | Integration |
|---|---|
| `Apps/XcodeSource` | Xcode-native SPM, source targets (control) |
| `Apps/XcodeBinary` | Xcode-native SPM, `binaryTarget`s (like `LocalPackages/BinaryDependencies`) |
| `Apps/XcodeDirect` | xcframeworks linked straight into the project |
| `Apps/TuistBinary` | Tuist `Tuist/Package.swift` + `.external(...)` |

## Rebuild everything

```bash
Scripts/build-xcframeworks.sh                         # Vendor sources -> Packages/BinaryPkg/Binaries
(cd Apps/XcodeBinary && xcodegen) ; (cd Apps/XcodeSource && xcodegen) ; (cd Apps/XcodeDirect && xcodegen)
(cd Apps/TuistBinary && tuist install && tuist generate --no-open)
Scripts/build-apps.sh                                 # xcodebuild each app with index store on
Scripts/check-index.sh .build/dd-XcodeBinary/Index.noindex/DataStore
Scripts/manual-index-probe.sh                         # raw swiftc, one flag varied at a time
```

`Tools/indexdump` (built from `Tools/indexdump.c` against the toolchain's `libIndexStore.dylib`)
lists which symbols have a *definition/declaration* in an index store, which is what Open Quickly surfaces.

## Manual IDE check (Open Quickly, ⇧⌘O)

For each app: open the project, wait for "Indexing" to finish, then ⇧⌘O and type each name:

| Query | Source | Binary |
|---|---|---|
| `SwiftKitPlaybackController` | | |
| `SwiftKitTrackModel` | | |
| `EngineSwiftMixHandler` | | |
| `OBJKAudioMixer` | | |
| `EngineCMixHandle` | | |

⌘-click on a binary Swift type opens the generated interface of the whole module rather than a
per-class file. That is expected (no source is shipped), a UX issue rather than an indexing bug.

## Rebuilding with another Xcode

```bash
export DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer
Scripts/build-xcframeworks.sh && Scripts/build-apps.sh && Scripts/report.sh
```

Outputs are separated per Xcode build under `.build/<build>/`. Build the xcframeworks with the
*oldest* Xcode under test: newer compilers read older `.swiftinterface`s, not the reverse.

## Findings so far (Xcode 27.0 / Swift 6.4, command-line builds)

- Binary **Swift** types are never in the build's index store, in all three binary integrations.
  Binary ObjC/C types and all source types are indexed.
- Not caused by explicit modules (`SWIFT_ENABLE_EXPLICIT_MODULES=NO` changes nothing), `-Fsystem`,
  or `-index-system-modules`.
- Root cause on the compiler side is by design, in `lib/Index/IndexRecord.cpp`: serialized Swift
  modules are indexed only when `isNonUserModule()`, i.e. the module lives under the SDK/platform or
  toolchain resource dir ("We don't officially support binary swift modules"). This logic predates
  Xcode 26 (present since at least Swift 5.9). Not a regression: binary Swift was never findable;
  the previous engine was ObjC, whose headers are indexed.
- A one-off check with a *mixed* binary framework (Swift + C headers in one framework, the
  pre-split engine layout) lost the C symbols from the index too; with C in its own framework the
  C part is indexed. This is why splitting the C part into its own framework helps. Variant not kept.
- IDE index (Xcode 27, projects opened in the GUI, `DerivedData/<App>-*/Index.noindex`): identical
  to the command-line result: binary Swift types are absent from both `DataStore` and `UniDB`;
  binary ObjC/C types are present. The IDE does not fill the gap the compiler leaves.

## Rendering (⌘-click on binary Swift types)

- SwiftKit is built with `-Xfrontend -group-info-path` (one module group per source file; groups
  live in the shipped `.swiftdoc`). SourceKit then serves a per-class generated interface
  (`editor.open.interface` + `key.groupname`) instead of the whole module, confirmed in the Xcode 27 UI
  (types sharing a file share a view). Groups do not affect indexing / Open Quickly.
- Generated interfaces are printed with a fixed 4-space indent and no line wrapping (a 10-parameter
  method is one ~350-char line). Nothing in the SourceKit request controls formatting today.
- `.swiftsourceinfo` makes Jump to Definition open real source only if the file exists at the path
  recorded at build time.

## Workaround attempts without a compiler change (all failed on Xcode 27)

- No flag exists: `isNonUserModule()` is purely "real path under SDK / platform / toolchain" (symlinks
  resolved). `-Fsystem`, `-index-system-modules`, explicit modules on/off change nothing.
- A `.swiftinterface` **can** be indexed by compiling it as the main module:
  `swift-frontend -frontend -typecheck -primary-file X.swiftinterface -module-name X -parse-as-library
  -index-store-path ...` gives 0 errors, USRs identical to a source build (`s:8SwiftKit0aB12MixerConsoleC`).
- Injecting those units into Xcode's live store (`DerivedData/<App>-*/Index.noindex/DataStore`):
  UniDB ingests them, but Open Quickly symbol search still doesn't show them, also not after
  reopening, and not with the `.swiftinterface` files added to the project (the *file* then shows
  in Open Quickly and ⌃6 lists its types, but symbols don't). Likely Open Quickly only surfaces
  units produced by / linked from Xcode's own compile tasks; the compiler's skip path also records
  the app-to-module dependency *without* a unit name, which an external writer can't fix.
- Even if it worked, results would land in the raw `.swiftinterface` (fully-qualified `Swift::Int`,
  no doc comments), which is worse than the generated interface.

## Compiler prototype: `-index-binary-modules`

Patched compiler: `gildor/swift` branch `index-binary-modules` (from `release/6.4.x`), installed as a
prototype toolchain `~/Library/Developer/Toolchains/swift-index-binary-modules.xctoolchain`
(copy of Xcode 27's toolchain with the patched `swift-frontend`).

- Raw probe: with `-index-binary-modules` all binary Swift types are DEFINED; without it, unchanged.
  Same USRs as a source build; location is the framework's (`.private`)`.swiftinterface`.
  A module compiled from source and imported is still not indexed from its `.swiftmodule`.
- `Apps/XcodeDirectIndexed`: XcodeDirect + `OTHER_SWIFT_FLAGS = -Xfrontend -index-binary-modules`.
  Build with `TOOLCHAINS=app.gildor.swift.index-binary-modules` (or Xcode > Toolchains).
  Extra settings are needed only because a locally built open-source compiler is mixed into
  Xcode 27's Apple-internal toolchain: `SWIFT_USE_INTEGRATED_DRIVER=NO` (Xcode's in-process driver
  rejects frontend flags it doesn't know), `SWIFT_ENABLE_EXPLICIT_MODULES=NO` and
  `SDK_STAT_CACHE_ENABLE=NO` (Apple clang args unknown to open-source clang),
  `APP_SHORTCUTS_ENABLE_FLEXIBLE_MATCHING=NO`. The SPM variant fails because SwiftPM passes
  Xcode's internal `-stack-check`; the prototype branch carries a do-not-upstream shim for it.
- Upstreaming needs the option in **swift-driver** too (Xcode's integrated driver validates
  `-Xfrontend` options), i.e. swiftlang/swift + swiftlang/swift-driver.
- **Xcode UI result (Xcode 27 + prototype toolchain, `Apps/XcodeDirectIndexed`):** Open Quickly finds
  `SwiftKitMixerConsole` from the binary framework. With binary-indexed module units marked as
  *system* (like SDK modules), selecting the result opens the generated (per-group) interface
  instead of the raw `.private.swiftinterface`.
