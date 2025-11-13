// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedMessaging",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "SharedMessaging",
            targets: ["SharedMessaging"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.1"),
    ],
    targets: [
        .target(
            name: "SharedMessaging",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Sodium", package: "swift-sodium"),
            ]
        ),
    ]
)
