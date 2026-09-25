// swift-tools-version: 5.9
// A typical app setup: one local package, many binaryTargets,
// with a Swift xcframework shipped as one product together with the C xcframework it imports.
import PackageDescription

let package = Package(
    name: "BinaryPkg",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "SwiftKit", targets: ["SwiftKit"]),
        .library(name: "ObjCKit", targets: ["ObjCKit"]),
        .library(name: "EngineSwift", targets: ["EngineSwift", "EngineC"]),
    ],
    targets: [
        .binaryTarget(name: "SwiftKit", path: "Binaries/SwiftKit.xcframework"),
        .binaryTarget(name: "ObjCKit", path: "Binaries/ObjCKit.xcframework"),
        .binaryTarget(name: "EngineSwift", path: "Binaries/EngineSwift.xcframework"),
        .binaryTarget(name: "EngineC", path: "Binaries/EngineC.xcframework"),
    ]
)
