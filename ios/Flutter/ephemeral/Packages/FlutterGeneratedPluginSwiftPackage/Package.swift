// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "app_links", path: "../.packages/app_links-7.2.1"),
        .package(name: "audio_service", path: "../.packages/audio_service-0.18.19"),
        .package(name: "audio_session", path: "../.packages/audio_session-0.2.4"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus-13.2.0"),
        .package(name: "image_gallery_saver_plus", path: "../.packages/image_gallery_saver_plus-5.0.0"),
        .package(name: "just_audio", path: "../.packages/just_audio-0.10.6"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-10.2.0"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.4.10"),
        .package(name: "share_plus", path: "../.packages/share_plus-13.2.0"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3+1"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.1"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.26.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "app-links", package: "app_links"),
                .product(name: "audio-service", package: "audio_service"),
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "image-gallery-saver-plus", package: "image_gallery_saver_plus"),
                .product(name: "just-audio", package: "just_audio"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
