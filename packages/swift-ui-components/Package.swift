// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DelaxSwiftUIComponents",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DelaxSwiftUIComponents",
            targets: ["DelaxSwiftUIComponents"]
        ),
    ],
    dependencies: [
        // No external dependencies to keep it lightweight
    ],
    targets: [
        .target(
            name: "DelaxSwiftUIComponents",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DelaxSwiftUIComponentsTests",
            dependencies: ["DelaxSwiftUIComponents"],
            path: "Tests"
        ),
    ]
)