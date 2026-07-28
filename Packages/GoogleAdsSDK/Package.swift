// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GoogleAdsSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "GoogleMobileAds",
            targets: ["GoogleMobileAdsTarget"]
        ),
        .library(
            name: "GoogleUserMessagingPlatform",
            targets: ["UserMessagingPlatformTarget"]
        ),
    ],
    targets: [
        .target(
            name: "GoogleMobileAdsTarget",
            dependencies: [
                .target(name: "GoogleMobileAds"),
                .target(name: "UserMessagingPlatformTarget"),
            ]
        ),
        .target(
            name: "UserMessagingPlatformTarget",
            dependencies: [
                .target(name: "UserMessagingPlatform"),
            ],
            linkerSettings: [
                .linkedFramework("WebKit"),
            ]
        ),
        .binaryTarget(
            name: "GoogleMobileAds",
            url: "https://dl.google.com/googleadmobadssdk/e89ba382a6244f5c/googlemobileadsios-spm-13.7.0.zip",
            checksum: "e89ba382a6244f5c8d92941015b12d98678689ebe14960eaa4c1d5951784a9c2"
        ),
        .binaryTarget(
            name: "UserMessagingPlatform",
            url: "https://dl.google.com/googleadmobadssdk/90fe6bf3b0f4ce0d/googleusermessagingplatformios-spm-3.1.0.zip",
            checksum: "90fe6bf3b0f4ce0d0199628c0871de58b6f673375148b98d52348aecc86db231"
        ),
    ]
)
