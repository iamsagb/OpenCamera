// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "OpenCamera",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "OpenCamera",
            targets: ["OpenCamera"]
        )
    ],
    targets: [
        .target(
            name: "OpenCamera",
            path: "Sources/OpenCamera"
        ),
        .testTarget(
            name: "OpenCameraTests",
            dependencies: ["OpenCamera"],
            path: "Tests/OpenCameraTests"
        )
    ]
)
