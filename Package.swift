// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.12.0")),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.10")),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.2.0"))
]
let targets: [Target] = [
    .target(name: "PassGenerator", dependencies: ["NIO", "ZIPFoundation", "CryptoSwift"]),
    .testTarget(name: "PassGeneratorTests", dependencies: ["PassGenerator"])
]
let products: [Product] = [
    .library(name: "PassGenerator", targets: ["PassGenerator"])
]
let package = Package(name: "PassGenerator", platforms: [.macOS(.v10_13)], products: products, dependencies: dependencies, targets: targets)
