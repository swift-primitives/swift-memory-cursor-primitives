// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-memory-cursor-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Memory Cursor Primitives",
            targets: ["Memory Cursor Primitives"]
        ),
        .library(
            name: "Memory Cursor Primitives Test Support",
            targets: ["Memory Cursor Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-cursor-primitives"),
        .package(path: "../swift-byte-primitives"),
        .package(path: "../swift-byte-cursor-primitives"),
        .package(path: "../swift-cardinal-primitives"),
        .package(path: "../swift-memory-primitives"),
        .package(path: "../swift-ordinal-primitives"),
        .package(path: "../swift-tagged-primitives"),
    ],
    targets: [
        .target(
            name: "Memory Cursor Primitives",
            dependencies: [
                .product(name: "Cursor Primitive", package: "swift-cursor-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),
        .target(
            name: "Memory Cursor Primitives Test Support",
            dependencies: [
                "Memory Cursor Primitives",
                .product(name: "Cursor Primitives Test Support", package: "swift-cursor-primitives"),
                .product(name: "Byte Primitives Test Support", package: "swift-byte-primitives"),
                .product(name: "Byte Cursor Primitives Test Support", package: "swift-byte-cursor-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Memory Cursor Primitives Tests",
            dependencies: [
                "Memory Cursor Primitives",
                "Memory Cursor Primitives Test Support",
                .product(name: "Byte Cursor Primitives", package: "swift-byte-cursor-primitives"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
