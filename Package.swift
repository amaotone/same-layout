// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DisplayCycle",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "DisplayCycle")
    ]
)
