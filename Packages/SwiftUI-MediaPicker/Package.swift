// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI-MediaPicker",
    platforms: [
        .iOS(.v14), .macOS(.v11),
    ],
    products: [
        .library(
            name: "MediaPicker",
            targets: ["MediaPicker"]),
    ],
    targets: [
        .target(
            name: "MediaPicker",
            dependencies: []),
        .testTarget(
            name: "MediaPickerTests",
            dependencies: ["MediaPicker"]),
    ]
)
