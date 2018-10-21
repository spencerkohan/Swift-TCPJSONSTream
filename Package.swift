// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

func localModulesPath(_ moduleName: String) -> String {
    return "../\(moduleName)"
    //return "/Users/spencerkohan/Projects/Personal/SwiftModules/\(moduleName)"
}

let package = Package(
    name: "TCPJSONStream",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TCPJSONStream",
            targets: ["TCPJSONStream"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/spencerkohan/Swift-TCP", .branch("master")),
        .package(url: "https://github.com/spencerkohan/Swift-EventEmitter", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "TCPJSONStream",
            dependencies: ["TCP", "EventEmitter"]),
        .testTarget(
            name: "TCPJSONStreamTests",
            dependencies: ["TCPJSONStream"]),
    ],
    swiftLanguageVersions: [.v4, .v4_2]
)
