// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMinor(from: "2.40.0")),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.5.1")),
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMinor(from: "1.4.2"))
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
let package = Package(
	name: "PassGenerator",
	platforms: [.macOS(.v10_15)],
	products: products,
	dependencies: dependencies,
	targets: targets,
	swiftLanguageVersions: [.v5]
)
