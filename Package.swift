// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SpeakMore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SpeakMore", targets: ["SpeakMore"])
    ],
    targets: [
        .executableTarget(
            name: "SpeakMore",
            path: "Sources/SpeakMore"
        ),
        .testTarget(
            name: "SpeakMoreTests",
            dependencies: ["SpeakMore"],
            path: "Tests/SpeakMoreTests"
        )
    ]
)
