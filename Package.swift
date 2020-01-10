// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PassGenerator",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PassGenerator",
            targets: ["PassGenerator"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "1.14.1")),
        .package(url: "https://github.com/vapor/core.git", .upToNextMajor(from: "3.9.0")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.9")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "PassGenerator",
            dependencies: ["NIO", "Core", "ZIPFoundation", "CryptoSwift"]),
        .testTarget(
            name: "PassGeneratorTests",
            dependencies: ["PassGenerator"]),
    ]
)
