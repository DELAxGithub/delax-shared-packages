// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DelaxSwiftUIComponents",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
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