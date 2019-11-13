// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PassGenerator",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PassGenerator",
            targets: ["PassGenerator"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.10.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.9")),
        .package(url: "https://github.com/vapor/open-crypto.git", from: "4.0.0-alpha.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "PassGenerator",
            dependencies: ["NIO", "ZIPFoundation", "OpenCrypto"]),
        .testTarget(
            name: "PassGeneratorTests",
            dependencies: ["PassGenerator"]),
    ]
)
