// swift-tools-version: 5.9
// Created by Ivo Valcic

import PackageDescription

let package = Package(
    name: "FFmpegMinimal",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "FFmpegMinimal",
            targets: ["FFmpegMinimal"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "FFmpegMinimal",
            url: "https://github.com/valcicivo/FFmpegMinimal/releases/download/0.1.0/FFmpegMinimal.xcframework.zip",
            checksum: "8c2cfa80c930a617dfe7f44c104ecddfaad3be4506abf3abee39433568a4d10c"
        ),
    ]
)
