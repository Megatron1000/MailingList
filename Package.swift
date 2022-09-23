// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MailingList",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "MailingList",
            targets: ["MailingList"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rhodgkins/SwiftHTTPStatusCodes", from: "3.3.0"),
    ],
    targets: [
        .target(
            name: "MailingList",
            dependencies: [
                .product(name: "HTTPStatusCodes", package: "SwiftHTTPStatusCodes")
            ],
            resources: [
      			.process("Resources/Assets.xcassets"),
      			.process("Resources/MailingList.storyboard"),
            ])
    ]
)
