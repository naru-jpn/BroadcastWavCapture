// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppGroupFiles",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AppGroupFiles",
            targets: ["AppGroupFiles"]),
    ],
    targets: [
        .target(
            name: "AppGroupFiles"),
        .testTarget(
            name: "AppGroupFilesTests",
            dependencies: ["AppGroupFiles"]
        ),
    ]
)
