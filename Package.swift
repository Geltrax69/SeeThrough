// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SeeThrough",
    platforms: [.macOS(.v14)],
    targets: [.executableTarget(name: "SeeThrough", path: "Sources/SeeThrough")]
)
