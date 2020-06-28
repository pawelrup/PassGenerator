// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.18.0")),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.3.1")),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.2.0")
]
let targets: [Target] = [
    .target(name: "PassGenerator", dependencies: [
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "CryptoSwift", package: "CryptoSwift")
    ]),
    .testTarget(name: "PassGeneratorTests", dependencies: ["PassGenerator"])
]
let products: [Product] = [
    .library(name: "PassGenerator", targets: ["PassGenerator"])
]
let package = Package(name: "PassGenerator", platforms: [.macOS(.v10_13)], products: products, dependencies: dependencies, targets: targets)
