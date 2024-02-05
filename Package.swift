// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseiOSMisebox",
    platforms: [
        .iOS(.v16) // Specify iOS 16 as the minimum deployment target
    ],
    products: [
        .library(
            name: "FirebaseiOSMisebox",
            targets: ["FirebaseiOSMisebox"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.1")
    ],
    targets: [
        .target(
            name: "FirebaseiOSMisebox",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "FirebaseiOSMiseboxTests",
            dependencies: ["FirebaseiOSMisebox"]
        )
    ]
)
