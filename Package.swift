// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BroadcastWavCapture",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BroadcastWavCapture",
            targets: ["BroadcastWavCapture"]),
    ],
    targets: [
        .target(
            name: "BroadcastWavCapture"),
        .testTarget(
            name: "BroadcastWavCaptureTests",
            dependencies: ["BroadcastWavCapture"]
        ),
    ]
)
