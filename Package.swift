// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseiOSMisebox",
    platforms: [
        .iOS(.v16), // Specify iOS 16 as the minimum deployment target
    ],
    products: [
        .library(
            name: "FirebaseiOSMisebox",
            targets: ["FirebaseiOSMisebox"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // Add Firebase as a dependency with a specific version
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.1") // Replace "10.19.1" with the desired version
    ],
    targets: [
        .target(
            name: "FirebaseiOSMisebox",
            dependencies: [
                // Specify dependencies for the target
                // Here, Firebase modules are specified as dependencies
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")

                // Add other necessary Firebase modules here
            ]),
        .testTarget(
            name: "FirebaseiOSMiseboxTests",
            dependencies: ["FirebaseiOSMisebox"]),
    ],
    // Specify the version of your package here
    version: "1.0.0"
)

