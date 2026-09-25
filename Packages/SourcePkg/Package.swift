// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SourcePkg",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "SwiftKit", targets: ["SwiftKit"]),
        .library(name: "ObjCKit", targets: ["ObjCKit"]),
        .library(name: "EngineSwift", targets: ["EngineSwift", "EngineC"]),
    ],
    targets: [
        .target(name: "SwiftKit"),
        .target(name: "ObjCKit", publicHeadersPath: "include"),
        .target(name: "EngineC", publicHeadersPath: "include"),
        .target(name: "EngineSwift", dependencies: ["EngineC"]),
    ]
)
