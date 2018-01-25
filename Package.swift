// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OysterKit",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "OysterKit",
            type: .static,
            targets: ["OysterKit"]
        ),
        .library(
            name: "STLR",
            type: .static,
            targets: ["STLR"]
        ),
        .library(
            name: "ExampleLanguages",
            type: .static,
            targets: ["ExampleLanguages"]
        ),
        .executable(
            name:"stlr",
            targets: ["stlr-cli"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "STLR",
            dependencies: ["OysterKit"]),
        .target(
            name: "OysterKit",
            dependencies: []),
        .target(
            name: "stlr-cli",
            dependencies: ["OysterKit","STLR"]),
        .target(
            name: "ExampleLanguages",
            dependencies: ["OysterKit"]),
        .testTarget(
            name: "OysterKitTests",
            dependencies: ["OysterKit","ExampleLanguages"]),
        .testTarget(
            name: "OysterKitPerformanceTests",
            dependencies: ["OysterKit","ExampleLanguages"]),
    ]
)
