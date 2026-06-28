// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OilPulse",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "OilPulse",
            path: "Sources/OilMonitor",
            linkerSettings: [.linkedLibrary("sqlite3")]
        )
    ]
)
