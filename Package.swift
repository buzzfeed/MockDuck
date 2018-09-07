// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "MockDuck",
    products: [
        .library(
            name: "MockDuck",
            targets: ["MockDuck"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MockDuck",
            dependencies: [],
            path: "MockDuck/Sources"),
        .testTarget(
            name: "MockDuckTests",
            dependencies: ["MockDuck"],
            path: "MockDuckTests/Sources"),
    ]
)
