// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DelaxCloudKitSharingKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DelaxCloudKitSharingKit",
            targets: ["DelaxCloudKitSharingKit"]
        ),
    ],
    dependencies: [
        // No external dependencies - kept lightweight following DELAX standards
    ],
    targets: [
        .target(
            name: "DelaxCloudKitSharingKit",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DelaxCloudKitSharingKitTests",
            dependencies: ["DelaxCloudKitSharingKit"],
            path: "Tests"
        ),
    ]
)