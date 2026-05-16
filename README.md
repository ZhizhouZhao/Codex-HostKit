# Codex HostKit

<p align="center">
  <img alt="Release" src="https://img.shields.io/github/v/release/ZhizhouZhao/Codex-HostKit">
  <img alt="Platform" src="https://img.shields.io/badge/macOS-14%2B-black">
  <img alt="Arch" src="https://img.shields.io/badge/arch-arm64%20%7C%20x86__64-blue">
  <img alt="License" src="https://img.shields.io/github/license/ZhizhouZhao/Codex-HostKit">
</p>

Codex HostKit 是给 Codex / Codex++ 用户用的 macOS 本机辅助工具：配置自己的 API / 中转站、准备 Codex Mobile 本地 host、保存插件快照、找回本地对话。

English: A small macOS helper for local Codex/Codex++ provider config, plugin snapshots, mobile host readiness, and session recovery.

## 快速下载

下载最新版 DMG：

[Codex-HostKit-0.1.0.dmg](https://github.com/ZhizhouZhao/Codex-HostKit/releases/download/v0.1.0/Codex-HostKit-0.1.0.dmg)

终端下载并校验：

```bash
cd ~/Downloads && \
curl -L -o Codex-HostKit-0.1.0.dmg https://github.com/ZhizhouZhao/Codex-HostKit/releases/download/v0.1.0/Codex-HostKit-0.1.0.dmg && \
echo "2146d4f93ba48457b919504a6c64b03792343c1b2c9b10045d4ac37ea929c811  Codex-HostKit-0.1.0.dmg" | shasum -a 256 -c - && \
open Codex-HostKit-0.1.0.dmg
```

要求：macOS 14+，支持 Apple Silicon 和 Intel Mac。

第一次打开如果提示无法验证开发者：右键 `Codex HostKit.app`，选择 `打开`。

## 功能亮点

- Provider 配置：解析 API key、Base URL、JSON、cURL，写入 `~/.codex/config.toml`。
- Keychain 保存：API key 保存到 macOS Keychain，不明文塞进配置文件。
- Codex Mobile：让手机连接 Mac host / local thread 时走 Mac 本地 provider。
- Codex++ 同步：同步 `launchctl` 和 watcher 环境，减少切换 provider 后失效。
- 插件快照：备份本机已有插件缓存，生成本地 marketplace 快照。
- 对话找回：扫描本地 sessions / history，搜索、预览、导出 Markdown / JSON。
- 维护诊断：检查 app-server、9229 端口、watcher plist、sessions 大小等状态。

## 适合谁

- 想在 Mac 本地 Codex 使用自己的 API / 中转站。
- 想保留 Codex Mobile，但请求仍走 Mac 本地配置。
- 经常在 Codex、Codex++、不同 provider 之间切换。
- 本地插件或历史对话偶尔“看起来不见了”。

## 基本用法

1. 打开 `Codex HostKit`
2. 粘贴 API key、Base URL、JSON 或 cURL
3. 点击解析并保存到 Keychain
4. 应用 Codex 配置
5. 需要 Codex++ 时，同步到 `launchctl` / watcher
6. 打开 Codex / Codex++
7. 手机端选择 Mac host / local thread

不要选择 Cloud thread。Cloud thread 不读取你 Mac 上的 `~/.codex/config.toml`。

## 这个工具不会做什么

- 不破解 Codex
- 不绕过 ChatGPT / Codex 账号权限
- 不下载你没有权限访问的官方插件
- 不绕过 Google / Gmail / Drive OAuth
- 不上传你的 API key、插件缓存或 sessions

HostKit 只管理你本机已有的配置、缓存和历史。

## 赞赏支持

如果这个工具帮到了你，可以请我喝杯咖啡。

<p align="center">
  <img src="CodexPlusPlusCompanion/Resources/DonateAlipay.jpeg" alt="支付宝赞赏码" width="220">
  <img src="CodexPlusPlusCompanion/Resources/DonateWechat.jpeg" alt="微信赞赏码" width="220">
</p>

## FAQ

### Intel Mac 可以用吗？

可以。v0.1.0 的 DMG 已经是 Universal 包，包含 `x86_64 arm64`。

### 手机 Codex Mobile 可以直接填 API key 吗？

不可以。API key 配在 Mac 本地 Codex。手机端连接 Mac host / local thread。

### 为什么还要登录 ChatGPT？

手机端需要账号来找到并连接你的 Mac host。模型请求是否走自己的 API，取决于 Mac 本地 Codex 配置。

### 插件快照能代替插件商店吗？

不能。它只保存本机已有插件缓存，不下载受限插件，也不绕过 OAuth。

### 会上传我的 API key 或对话吗？

不会。API key 存在 macOS Keychain，sessions 扫描和导出都在本机完成。

## 从源码运行

```bash
git clone https://github.com/ZhizhouZhao/Codex-HostKit.git
cd Codex-HostKit
open CodexPlusPlusCompanion.xcodeproj
```

Xcode 中选择 `CodexPlusPlusCompanion` scheme，运行目标选择 `My Mac`。

命令行构建 Universal Release：

```bash
xcodebuild -project CodexPlusPlusCompanion.xcodeproj \
  -scheme CodexPlusPlusCompanion \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  build
```

## License

MIT License. See [LICENSE](LICENSE).
