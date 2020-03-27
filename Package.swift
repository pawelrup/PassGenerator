// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.15.0")),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.3.0"))
]
let targets: [Target] = [
    .target(name: "PassGenerator", dependencies: [
        .product(name: "NIO", package: "swift-nio"),
        "CryptoSwift"
    ]),
    .testTarget(name: "PassGeneratorTests", dependencies: ["PassGenerator"])
]
let products: [Product] = [
    .library(name: "PassGenerator", targets: ["PassGenerator"])
]
let package = Package(name: "PassGenerator", platforms: [.macOS(.v10_13)], products: products, dependencies: dependencies, targets: targets)
