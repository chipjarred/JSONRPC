// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONRPC",
    platforms: [.macOS(.v10_15), .iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "JSONRPC",
            targets: ["JSONRPC"]),
        .library(
            name: "JSONRPC-Examples",
            targets: ["JSONRPC-Examples"]),
    ],
    dependencies: [
        .package(url: "https://github.com/chipjarred/Async.git", from: "1.0.3"),
        .package(url: "https://github.com/chipjarred/NIX.git", from: "0.0.10"),
        .package(
            url: "https://github.com/chipjarred/SimpleLog.git",
            .branch("main")
        ),
    ],
    targets: [
        .target(
            name: "JSONRPC",
            dependencies: ["Async", "NIX", "SimpleLog"]),
        .target(
            name: "JSONRPC-Examples",
            dependencies: ["JSONRPC", "NIX"]),
        .testTarget(
            name: "JSONRPCTests",
            dependencies: ["JSONRPC"]),
    ]
)
