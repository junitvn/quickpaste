// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickPaste",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.16.1"),
    ],
    targets: [
        .executableTarget(
            name: "QuickPaste",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "Sources/QuickPaste",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
