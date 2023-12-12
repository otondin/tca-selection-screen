// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureSelection",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FeatureSelection",
            targets: ["FeatureSelection"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../ComponentLibrary"),
        .package(path: "../Models"),
        .package(path: "../Services"),
        .package(path: "../Localization"),
        
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FeatureSelection",
            dependencies: [
                "ComponentLibrary",
                "Models",
                "Services",
                "Utilities",
                "Localization",
                
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "FeatureSelectionTests",
            dependencies: ["FeatureSelection"]),
    ]
)
