# AGENTS.md

本仓库不是源码项目，而是微信 OpenSDK（腾讯）iOS **二进制分发仓库**。仓库内仅包含一个预编译的 `WechatOpenSDK.xcframework`，没有任何源码、构建脚本、测试、lint 或 typecheck 配置。不要尝试运行 `xcodebuild`、`pod`、`npm` 等命令——此处无对应工程文件。

## 仓库结构

- 顶层只有 `WechatOpenSDK.xcframework/`，没有 `README.md`、没有 `.git`、没有 `Package.swift` / `Podspec` / `*.xcodeproj`。
- SDK 版本：**2.0.5**（见 `WechatOpenSDK.xcframework/README.txt`，该文件是版本变更日志，不是集成文档）。
- xcframework 两个 slice：
  - `ios-arm64/` — 真机（arm64）
  - `ios-arm64_x86_64-simulator/` — 模拟器（arm64 + x86_64）
- 每个 slice 内的 `WechatOpenSDK.framework/WechatOpenSDK` 是 **静态库（Mach-O `ar archive`）**，不是动态 framework。集成时必须链接而非嵌入。
- 公开头文件位于 `WechatOpenSDK.framework/Headers/`：`WechatOpenSDK.h`（umbrella）、`WXApi.h`、`WXApiObject.h`、`WechatAuthSDK.h`。`Modules/module.modulemap` 已配置，支持 `@import WechatOpenSDK;`。
- `PrivacyInfo.xcprivacy` 已声明 `NSPrivacyAccessedAPICategoryUserDefaults`（理由 `CA92.1`），随 xcframework 一起分发，宿主 App 无需再重复声明此项。

## 集成时容易踩坑的点（来自 `README.txt` 与头文件，已核实）

- **头文件引用格式**：2.0.5 起改为模块化格式 `#import <WechatOpenSDK/WXApi.h>`，不要再写老的 `#import "WXApi.h"`，否则可能与其它版本路径冲突。
- **Linker Flags**：宿主工程 `Other Linker Flags` 必须加 `-Objc -all_load`，否则分类/静态库符号会被剥离导致运行时 `unrecognized selector`。
- **必须链接的系统框架**：`Security.framework`、`CFNetwork.framework`、`SystemConfiguration.framework`、`CoreTelephony.framework`（具体见 README.txt 中 1.7.4 / 1.5 条目）。
- **Info.plist 必配项**：
  - `LSApplicationQueriesSchemes` 至少包含 `weixin`；用到 `isWXAppSupportStateAPI` 需加 `weixinStateAPI`，用到 `isWXAppSupportQRCodePayAPI` 需加 `weixinQRCodePayAPI`。
  - `NSAppTransportSecurity` → `NSAllowsArbitraryLoads = true`（老版本兼容要求，README.txt 1.6 条目）。
- **`BUILD_WITHOUT_PAY` 预处理宏**：在头文件中 `#ifndef BUILD_WITHOUT_PAY` 守卫了所有支付相关接口（`PayReq`/`PayResp`、`WXOfflinePay*`、`WXNontaxPay*`、`WXPayInsurance*`、`WXQRCodePay*`，以及 `WXApi.h` 的 `isWXAppSupportQRCodePayAPI`）。若宿主 App 不需要支付能力，可在宿主工程定义该宏以剔除支付符号；需要支付时**不要**定义它。
- **iOS 16+ 剪切板回调**：`WXApiDelegate` 的 `onNeedGrantReadPasteBoardPermissionWithURL:completion:` 是 iOS 16+ 才回调的可选方法。不实现时 SDK 会直接读剪切板；实现后必须调用 `completion()`，否则收不到 `onReq:`/`onResp:`，业务流程会中断。不要长时间持有 `completion` block（会内存泄漏）。详见 `WXApi.h` 注释。

## 工作约定

- 本仓库**不是 git 仓库**（无 `.git` 目录）。如需提交、打 tag、发版，需先与用户确认是否要 `git init` 以及目标远端，不要擅自初始化。
- 仓库内没有任何可验证代码的命令；改动只可能发生在二进制替换（新版 SDK 下发）或新增集成文档/示例。替换 SDK 前后可通过 `ls -la WechatOpenSDK.xcframework/ios-arm64/WechatOpenSDK.framework/WechatOpenSDK` 与 `file` 命令核对二进制时间戳与架构，不要试图反编译。
- 查 API 时直接读 `Headers/*.h`，`README.txt` 仅是版本变更日志，不含完整 API 文档。
