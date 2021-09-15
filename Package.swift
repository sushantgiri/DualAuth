// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DualAuthiOS",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DualAuthiOS",
            targets: ["DualAuthiOS"]),
    ],
   
    dependencies: [
        
        // Dependencies declare other packages that this package depends on.
        .package(name: "CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.4.0")),
        .package(name: "secp256k1", url: "https://github.com/Boilertalk/secp256k1.swift.git", .upToNextMajor(from: "0.1.4")),
        .package(name: "Web3", url: "https://github.com/Boilertalk/Web3.swift.git", from: "0.5.0")
//        .package(name: "Web3",url: "https://github.com/Boilertalk/Web3.swift.git",
//            .upToNextMajor(from: "0.5.0")),
        
    ],
       
       
    
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DualAuthiOS",
            dependencies: [
                           .product(name: "CryptoSwift", package: "CryptoSwift"),
                           .product(name: "secp256k1", package: "secp256k1"),
                           .product(name: "Web3", package: "Web3"),
                           .product(name: "Web3PromiseKit", package: "Web3"),
                           .product(name: "Web3ContractABI", package: "Web3"),
            ],
            resources: [
                .process("wallet/abi.json")
            ]),
    
        .testTarget(
            name: "DualAuthiOSTests",
            dependencies: ["DualAuthiOS"]),
    ]
)
