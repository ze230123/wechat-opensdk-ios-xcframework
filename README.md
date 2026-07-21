# WechatOpenSDK (iOS) — SPM 二进制分发

微信开放平台 OpenSDK（腾讯）iOS 版的 Swift Package Manager 二进制分发仓库。

- 当前 SDK 版本：**2.0.5**
- 支持架构：真机 `arm64`、模拟器 `arm64` + `x86_64`

## 通过 SPM 集成

1. Xcode → File → Add Packages…
2. 输入仓库地址：
   ```
   https://github.com/ze230123/wechat-opensdk-ios-xcframework
   ```
3. Dependency rule 选 **Up to Next Major Version: 2.0.5**，Add Package。
4. 在 target 的 Frameworks, Libraries, and Embedded Content 中确认 `WechatOpenSDK` 已添加（Embed 设置为 Do Not Embed，因为是静态库）。

## License

`WechatOpenSDK.xcframework` 本体的版权归腾讯所有，使用须遵守[微信开放平台服务协议](https://open.weixin.qq.com/)。本仓库仅作为 SPM binary target 分发包装。
