# Codex HostKit

Codex HostKit 是一个 macOS 本机辅助工具，面向需要在 Mac 上使用 Codex、配置 OpenAI-compatible provider、保留手机扫码连接能力、管理本机插件快照和找回本地对话记录的用户。

它的核心定位很简单：把原本需要手动改 `~/.codex/config.toml`、Keychain、`launchctl`、watcher plist、插件缓存和 sessions 的本机操作，整理成一个更清晰、更安全的图形界面。

## Codex HostKit 是什么

- 本机 provider 配置工具：解析 API key、base URL、model、JSON 或 cURL，并写入 Codex 本机配置。
- 手机扫码连接说明工具：帮助确认手机 ChatGPT 控制的是 Mac host / local thread，而不是 Cloud thread。
- 插件快照工具：备份和恢复这台 Mac 上已经存在的插件缓存，并生成本地 marketplace 索引。
- 对话找回工具：扫描本机 Codex sessions 和 history，帮助找回看起来消失的本地 thread。
- 维护诊断工具：检查本机 config、Keychain、环境变量、watcher、sessions、插件缓存和端口状态。

## 不是什么

- 不绕过 ChatGPT、Codex、插件或 OAuth 的账号权限。
- 不解锁官方服务端限制，也不下载官方受限插件。
- 不替代 Codex，只管理本机配置、缓存、历史和连接诊断。
- 不托管、不上传、不明文保存用户 API key。
- 不自动杀掉 Codex 进程；维护脚本只生成文本，交给用户审阅后手动运行。

## 适合谁使用

- 正在 macOS 上使用 Codex，希望减少手动改配置的用户。
- 希望本机 Codex 请求走 OpenAI-compatible provider 的用户。
- 希望手机继续扫码连接 Mac host，但模型请求按本机 provider 计费的用户。
- 插件入口或插件列表因为网络环境变化而不稳定，想备份本机插件缓存的用户。
- 切换账号、provider、watcher 或 app-server 后，本地对话列表看起来不完整的用户。

## Mac 部署教程

### 方式一：终端下载 DMG

普通用户可以打开 macOS 自带的 `终端`，复制下面这段命令并回车：

```sh
cd ~/Downloads && \
curl -L -o Codex-HostKit-0.1.0.dmg https://github.com/ZhizhouZhao/Codex-HostKit/releases/download/v0.1.0/Codex-HostKit-0.1.0.dmg && \
echo "3227456bee877710b3245c828addb5f57b5fbde0744024e68811a9c8ce9d8e03  Codex-HostKit-0.1.0.dmg" | shasum -a 256 -c - && \
open Codex-HostKit-0.1.0.dmg
```

命令完成后，会自动打开 DMG。把 `Codex HostKit.app` 拖到 `Applications`，再从 `Applications` 打开 `Codex HostKit`。

如果校验失败，终端会显示 `FAILED`，请删除下载的 DMG 后重新下载。

当前版本使用本地构建签名，未做 Apple notarization。如果 macOS 提示“无法验证开发者”，可以到 `系统设置 -> 隐私与安全性`，在底部允许打开；也可以右键点击 App 后选择 `打开`。

### 方式二：网页下载 DMG

也可以直接在 GitHub Releases 下载 `Codex-HostKit-*.dmg`。

1. 打开最新 Release。
2. 下载 DMG 文件。
3. 双击打开 DMG。
4. 把 `Codex HostKit.app` 拖到 `Applications`。
5. 从 `Applications` 打开 `Codex HostKit`。

### 方式三：从源码运行

#### 1. 准备环境

- macOS 14 或更新版本。
- Xcode 26 或更新版本。
- 已安装并可正常打开 Codex。

#### 2. 克隆仓库

```sh
git clone https://github.com/ZhizhouZhao/Codex-HostKit.git
cd Codex-HostKit
```

如果你使用 SSH：

```sh
git clone git@github.com:ZhizhouZhao/Codex-HostKit.git
cd Codex-HostKit
```

#### 3. 用 Xcode 运行

1. 打开 `CodexPlusPlusCompanion.xcodeproj`。
2. 在 Xcode 顶部选择 `CodexPlusPlusCompanion` scheme。
3. 运行目标选择 `My Mac`。
4. 点击 Run。
5. 启动后的 App 显示名称是 `Codex HostKit`。

内部 target、bundle id 和 Keychain service 仍保留历史名称 `CodexPlusPlusCompanion`，这是为了兼容已有本机配置和钥匙串记录。

## 命令行构建

Debug 构建：

```sh
xcodebuild -project CodexPlusPlusCompanion.xcodeproj \
  -scheme CodexPlusPlusCompanion \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

Release 构建：

```sh
xcodebuild -project CodexPlusPlusCompanion.xcodeproj \
  -scheme CodexPlusPlusCompanion \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

构建产物通常位于 Xcode DerivedData，例如：

```text
~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/Codex HostKit.app
```

## 首次使用流程

### 1. 配置 Provider

打开 `Provider 配置` 页面，粘贴下面任意一种内容：

- API key，例如 `sk-...`
- base URL，例如 `https://example.com/v1`
- JSON，例如 `{"key":"sk-...","url":"https://example.com"}`
- cURL，例如带有 `Authorization: Bearer ...` 的请求

点击 `解析 Provider 信息` 后，确认 base URL、model 和 key 识别结果。

### 2. 保存密钥

点击 `保存到 Keychain`。API key 会写入 macOS Keychain，不会明文写进日志或配置文件。

### 3. 应用 Codex 配置

点击 `应用 Codex 配置`。工具会写入 `~/.codex/config.toml`，并在写入前自动备份旧文件。

### 4. 同步环境变量

按需点击：

- `同步到 launchctl`：让后续启动的本机 Codex 进程能读取环境变量。
- `同步到 Watcher`：把 API key 写入本机 watcher plist 的 EnvironmentVariables，并先备份 plist。

### 5. 手机扫码连接

1. Mac 和手机上的 ChatGPT 登录同一个账号。
2. 手机进入 Codex Mobile，扫描 Mac 上的二维码。
3. 选择 Mac host / local thread。
4. 不要选择 Cloud thread。
5. 新建一个 thread，发送 `Reply only ok`。
6. 回到 provider dashboard 检查是否出现请求记录。

如果 provider dashboard 有请求记录，说明手机只是控制 Mac，实际模型请求走的是 Mac 本机 provider 配置。

## 插件快照与对话找回

### 插件快照

`插件快照` 页面只处理本机已有插件缓存：

- 扫描 `~/.codex/plugins/cache`
- 备份到 `~/.codex/plugins/local-snapshot`
- 生成 `~/.agents/plugins/marketplace.json`

它不会下载官方受限插件，也不会绕过 OAuth 授权。Google、Gmail、Drive 等插件仍可能需要重新授权。Computer Use 等插件仍可能需要 macOS 屏幕录制和辅助功能权限。

### 对话找回

`对话找回` 页面只扫描本机 sessions 和 history：

- 帮助找到本地保存过的 thread。
- 支持预览、导出和备份。
- 不修改远端 ChatGPT Cloud 历史。

如果切换账号、provider、watcher 或 app-server 后对话列表不完整，可以先用这个页面检查本机记录。

## 安全说明

- API key 保存在 macOS Keychain。
- 命令输出会尽量隐藏敏感字段。
- 写入 config、plist、插件缓存和 marketplace 前会创建备份。
- 对话找回只读扫描本机历史，重置 sessions 时会把旧目录移动到带时间戳的备份位置。
- 维护诊断默认只读；清理脚本只生成文本，不会自动执行。
- 请不要把 API key 放进截图、issue、日志或公开讨论里。

## 常见问题

### 环境变量缺失

先在 `Provider 配置` 页面完成：

1. 解析 Provider 信息。
2. 保存到 Keychain。
3. 同步到 launchctl。
4. 按需同步到 watcher。

### 401 Invalid Token

确认 API key 属于当前 provider，并且 base URL 指向 OpenAI-compatible `/v1` endpoint。

### Idle timeout waiting for SSE

先使用非流式测试。如果非流式可用但流式失败，可能是 provider 对 Responses API streaming 的支持方式不同，或者服务端超时时间太短。

### 插件不显示

在 `插件快照` 页面恢复本地快照并生成本地 marketplace，然后重新打开 Codex。OAuth 插件可能仍需要重新授权。

### 手机一直卡在思考

完全关闭手机 ChatGPT 后重新打开，进入 Codex，选择 Mac host / local thread，新建 thread 后发送 `Reply only ok`。不要选择 Cloud thread。

### 有孤立 app-server 进程

打开 `维护诊断`，先运行只读诊断。如果发现孤立 app-server，生成清理脚本并审阅后再手动运行。

## License

MIT License. See [LICENSE](LICENSE).
