import ProjectDescription

let project = Project(
    name: "TuistBinary",
    targets: [
        .target(
            name: "TuistBinary",
            destinations: .iOS,
            product: .app,
            bundleId: "repro.TuistBinary",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            sources: ["../Shared/**"],
            dependencies: [
                .external(name: "SwiftKit"),
                .external(name: "ObjCKit"),
                .external(name: "EngineSwift"),
            ],
            settings: .settings(base: ["CODE_SIGNING_ALLOWED": "NO"])
        ),
    ]
)
