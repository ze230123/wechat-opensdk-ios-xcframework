# AGENTS.md

本仓库不是源码项目，而是微信 OpenSDK（腾讯）iOS **二进制分发仓库**。仓库内仅包含一个预编译的 `WechatOpenSDK.xcframework`，没有任何源码、构建脚本、测试、lint 或 typecheck 配置。不要尝试运行 `xcodebuild`、`pod`、`npm` 等命令——此处无对应工程文件。

## 仓库结构

- 顶层文件：`Package.swift`（SPM binary target 包装）、`AGENTS.md`、`.gitignore`；xcframework 本体**不进 git**（被 `.gitignore` 排除），仅通过 GitHub Release zip 分发。
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

- xcframework 本体和 zip 都不进 git（见 `.gitignore`），仅通过 GitHub Release asset 分发。集成方通过 SPM 拉取 Package.swift，再按其中 `binaryTarget` 的 url + checksum 下载 zip。
- 仓库内没有任何可验证代码的命令；改动只可能发生在二进制替换（新版 SDK 下发）或新增集成文档/示例。替换 SDK 前后可通过 `ls -la WechatOpenSDK.xcframework/ios-arm64/WechatOpenSDK.framework/WechatOpenSDK` 与 `file` 命令核对二进制时间戳与架构，不要试图反编译。
- 查 API 时直接读 `Headers/*.h`，`README.txt` 仅是版本变更日志，不含完整 API 文档。

## 改版流程（升级到 X.Y.Z）

每个版本 = 一个 GitHub Release + 一个 git tag，tag 号 = SDK 版本号 = `Package.swift` 中 url 的版本段。严格按顺序执行：

1. 替换本地 `WechatOpenSDK.xcframework/`（新版 SDK 下发），用 `head -3 WechatOpenSDK.xcframework/README.txt` 确认版本号，`file .../WechatOpenSDK.framework/WechatOpenSDK` 确认架构。
2. `find WechatOpenSDK.xcframework -name ".DS_Store" -delete` 清理噪声文件（否则 checksum 不稳定）。
3. `zip -r WechatOpenSDK-X.Y.Z.xcframework.zip WechatOpenSDK.xcframework -x "*.DS_Store" -x "*/.DS_Store"`。
4. `shasum -a 256 WechatOpenSDK-X.Y.Z.xcframework.zip | awk '{print $1}'` 算 checksum。
5. 更新 `Package.swift` 的 `url`（版本段同步）与 `checksum`；如新版有依赖/plist 变化，同步更新本文件"集成时容易踩坑的点"段。
6. `git add` + `git commit -m "Bump WechatOpenSDK to X.Y.Z"` + `git push origin main`。
7. `gh release create X.Y.Z WechatOpenSDK-X.Y.Z.xcframework.zip --title "WechatOpenSDK X.Y.Z" --notes "微信 OpenSDK X.Y.Z 二进制分发"`。`gh` 会基于当前 HEAD 自动打 tag `X.Y.Z`。
8. `curl -sL <url> | shasum -a 256` 验证远端 checksum 与本地一致；不一致说明上传有损坏，删 Release 重来。

**不可变约定**：

- 不要修改或强推已发布的 tag，发现 bug 就发新版本（如 `2.0.5.1` 或 `2.0.6`），否则集成方 SPM 缓存会错乱。
- zip 文件名必须带版本号 `WechatOpenSDK-X.Y.Z.xcframework.zip`，避免 Release asset 同名混淆。
- 顺序不能反：先打 zip 算 checksum → 改 `Package.swift` → commit → 再 `gh release create`，确保 tag 指向的 commit 已含正确的 `Package.swift`。
