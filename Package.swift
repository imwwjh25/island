// swift-tools-version: 5.9
// Vibe Island - macOS 菜单栏应用 SPM 配置

import PackageDescription

let package = Package(
    name: "VibeIsland",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VibeIsland",
            targets: ["VibeIsland"]
        )
    ],
    targets: [
        .executableTarget(
            name: "VibeIsland",
            path: "VibeIsland",
            exclude: [
                "Info.plist",
                "Resources/sounds/README.md"
            ],
            resources: [
                .copy("Resources/sounds")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "VibeIslandTests",
            dependencies: ["VibeIsland"],
            path: "VibeIslandTests"
        )
    ]
)
