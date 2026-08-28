// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "roamswitch-mcp",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "roamswitch-mcp",
            path: "Sources/roamswitch-mcp"
        ),
        .testTarget(
            name: "roamswitch-mcpTests",
            dependencies: ["roamswitch-mcp"],
            path: "Tests/roamswitch-mcpTests"
        ),
    ]
)
