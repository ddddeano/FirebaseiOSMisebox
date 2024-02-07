// swift-tools-version:5.9
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
        // Firebase SDK
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.1"),
        // Google Sign-In SDK
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "FirebaseiOSMisebox",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                // Include both GoogleSignIn and GoogleSignInSwift products
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ]
        ),
        .testTarget(
            name: "FirebaseiOSMiseboxTests",
            dependencies: ["FirebaseiOSMisebox"]
        )
    ]
)

