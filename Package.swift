// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "i2c",
    products: [
        .library(
            name: "i2c",
            targets: ["i2c"]),
    ],
    dependencies: [
        .package(url: "https://github.com/microswift-packages/hal-baseline", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "i2c",
            dependencies: [],
            path: ".",
            sources: ["i2c.swift"]),
    ]
)
