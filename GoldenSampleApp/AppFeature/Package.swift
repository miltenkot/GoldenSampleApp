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
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory", from: "2.5.3"),
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "NetworkRequests"
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"]
        ),
        .target(name: "NetworkRequests",
                dependencies: [
                    "NetworkService",
                    .product(name: "FactoryKit", package: "Factory")
                ]),
        .testTarget(name: "NetworkRequestsTests",
                    dependencies: ["NetworkRequests"]),
        .target(name: "NetworkService"),
        .testTarget(name: "NetworkServiceTests",
                    dependencies: [
                        "NetworkService"
                    ])
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
