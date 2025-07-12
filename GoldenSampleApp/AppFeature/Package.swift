// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .singleTargetLibrary("AppFeature")
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: ["NetworkRequests"]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"]
        ),
        .target(name: "NetworkRequests"),
        .testTarget(name: "NetworkRequestsTests",
                    dependencies: ["NetworkRequests"])
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
