// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Belt",
    platforms: [
        .iOS(.v14) // iOS 13 이상을 지원하도록 설정
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Belt",
            targets: ["Belt"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Belt"),
        .testTarget(
            name: "BeltTests",
            dependencies: ["Belt"]),
    ]
)
