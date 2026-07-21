# WechatOpenSDK (iOS) — SPM 二进制分发

微信开放平台 OpenSDK（腾讯）iOS 版的 Swift Package Manager 二进制分发仓库。仓库本体仅作为 SPM binary target 包装，**不包含 SDK 源码**；预编译的 xcframework 通过 GitHub Release zip 分发，集成方由 SPM 自动下载。

> 这是**非官方**的分发包装仓库，SDK 版权归腾讯所有。使用前请先在[微信开放平台](https://open.weixin.qq.com/)注册 App 并阅读官方[接入指南](https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=1417694084&lang=)。

- 当前 SDK 版本：**2.0.5**
- 支持架构：真机 `arm64`、模拟器 `arm64` + `x86_64`
- 二进制类型：**静态库**（Mach-O `ar archive`，需链接而非嵌入）
- 最低部署版本：iOS 13

## 通过 SPM 集成

1. Xcode → File → Add Packages…
2. 输入仓库地址：
   ```
   https://github.com/ze230123/wechat-opensdk-ios-xcframework
   ```
3. Dependency rule 选 **Up to Next Major Version: 2.0.5**，Add Package。
4. 在 target 的 Frameworks, Libraries, and Embedded Content 中确认 `WechatOpenSDK` 已添加（Embed 设置为 Do Not Embed，因为是静态库）。

## 集成后必做配置（漏一项会运行时崩溃或调起失败）

### 1. Other Linker Flags

Target → Build Settings → `Other Linker Flags` 加入：

```
-Objc -all_load
```

不加会导致 Objective-C 分类与静态库符号被剥离，运行时报 `unrecognized selector`。

### 2. 系统框架

Target → Build Phases → Link Binary With Libraries 加入：

- `Security.framework`
- `CFNetwork.framework`
- `SystemConfiguration.framework`
- `CoreTelephony.framework`

### 3. Info.plist

```xml
<!-- 检查微信是否安装 / 拉起微信所必需 -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <!-- 用到 isWXAppSupportStateAPI 时再加 -->
    <string>weixinStateAPI</string>
    <!-- 用到 isWXAppSupportQRCodePayAPI 时再加 -->
    <string>weixinQRCodePayAPI</string>
</array>

<!-- 老 ATS 兼容要求 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 4. 头文件引用格式

2.0.5 起改为模块化格式：

```objc
#import <WechatOpenSDK/WXApi.h>
#import <WechatOpenSDK/WXApiObject.h>
#import <WechatOpenSDK/WechatAuthSDK.h>
// 或 umbrella
#import <WechatOpenSDK/WechatOpenSDK.h>
```

Swift：

```swift
import WechatOpenSDK
```

不要再写老的 `#import "WXApi.h"`，否则可能与其它版本路径冲突。

## 隐私清单（PrivacyInfo.xcprivacy）

`WechatOpenSDK.xcframework` 内已附带 `PrivacyInfo.xcprivacy`，声明了 `NSPrivacyAccessedAPICategoryUserDefaults`（理由 `CA92.1`）。宿主 App **无需重复声明**此项。

## 可选项：剔除支付能力（`BUILD_WITHOUT_PAY`）

如果宿主 App 不需要微信支付能力，可在 Target → Build Settings → `Preprocessor Macros`（Debug 与 Release 都加）定义：

```
BUILD_WITHOUT_PAY
```

这会从 SDK 头文件中排除以下符号，避免无用符号进入二进制：

- `PayReq` / `PayResp`
- `WXOfflinePayReq` / `WXOfflinePayResp`
- `WXNontaxPayReq` / `WXNontaxPayResp`
- `WXPayInsuranceReq` / `WXPayInsuranceResp`
- `WXQRCodePayReq` / `WXQRCodePayResp`
- `WXApi` 的 `+ isWXAppSupportQRCodePayAPI`

需要支付时**不要**定义此宏。

## iOS 16+ 剪切板授权回调

iOS 16 起，SDK 读剪切板前会回调 `WXApiDelegate` 的可选方法：

```objc
- (void)onNeedGrantReadPasteBoardPermissionWithURL:(NSURL *)openURL
                                        completion:(WXGrantReadPasteBoardPermissionCompletion)completion;
```

- **不实现**：SDK 直接读剪切板（旧行为）。
- **实现**：必须调用 `completion()`，否则收不到 `onReq:` / `onResp:`，业务流程会中断。也不要长时间持有 `completion` block，会内存泄漏。

## 版本与变更日志

SDK 历史版本变更见仓库内 `WechatOpenSDK.xcframework/README.txt`（仅变更日志，不含 API 文档）。API 详情请直接查阅 `WechatOpenSDK.xcframework/ios-arm64/WechatOpenSDK.framework/Headers/`：

- `WXApi.h` — 所有 API 入口（`registerApp`、`sendReq`、`handleOpenURL` 等）
- `WXApiObject.h` — 请求/响应对象定义
- `WechatAuthSDK.h` — 扫码登录相关
- `WechatOpenSDK.h` — umbrella header

## 仓库维护

本仓库的版本发布、改版流程、集成注意事项见 [`AGENTS.md`](./AGENTS.md)。

- 每个版本对应一个 GitHub Release + 一个 git tag，tag 号 = SDK 版本号。
- `Package.swift` 中 `binaryTarget` 的 `url` 与 `checksum` 在每个版本发布时同步更新。
- xcframework 本体与 zip 文件**不提交进 git**，仅通过 Release asset 分发。

## License

- `WechatOpenSDK.xcframework` 本体的版权归腾讯所有，使用须遵守[微信开放平台服务协议](https://open.weixin.qq.com/)。
- 本仓库仅作为 SPM binary target 分发包装，不主张对 SDK 二进制本身的任何权利。
