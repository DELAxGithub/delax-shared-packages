// swift-tools-version: 5.9
// iOS Auto Bug Discovery Framework
// A comprehensive iOS bug detection and automatic reporting system

import PackageDescription

let package = Package(
    name: "iOSAutoBugDiscovery",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "iOSAutoBugDiscovery",
            targets: ["iOSAutoBugDiscovery"]
        ),
    ],
    dependencies: [
        // No external dependencies - uses system frameworks only
    ],
    targets: [
        .target(
            name: "iOSAutoBugDiscovery",
            dependencies: [],
            path: "Sources/iOSAutoBugDiscovery"
        ),
        .testTarget(
            name: "iOSAutoBugDiscoveryTests",
            dependencies: ["iOSAutoBugDiscovery"],
            path: "Tests/iOSAutoBugDiscoveryTests"
        ),
    ]
)