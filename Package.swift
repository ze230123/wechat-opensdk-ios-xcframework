// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "WechatOpenSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "WechatOpenSDK", targets: ["WechatOpenSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "WechatOpenSDK",
            url: "https://github.com/ze230123/wechat-opensdk-ios-xcframework/releases/download/2.0.5/WechatOpenSDK-2.0.5.xcframework.zip",
            checksum: "74e0f0432205783e930b16dd8c5149a5a04c70bcf456b87eef6d459bb254ae75"
        )
    ]
)
