// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TuistBinaryDeps",
    dependencies: [
        .package(path: "../../../Packages/BinaryPkg"),
    ]
)
