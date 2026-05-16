# Codex HostKit

一个给 Codex / Codex++ 用户用的 macOS 本机辅助工具。

我做它主要是为了解决几个很烦的问题：

- 手机 ChatGPT 里的 Codex Mobile 需要登录账号才能连接 Mac。
- 但我希望 Mac 本地 Codex 的模型请求走自己的 API / 中转站计费。
- 每次手动改 `~/.codex/config.toml`、`launchctl`、watcher plist 很麻烦。
- Codex++ 插件有时候不稳定，Computer Use / Google / Browser 这类插件可能要反复加载。
- 切换账号、API、Codex++ 或 app-server 后，本地对话有时看起来像丢了。

Codex HostKit 就是把这些本机操作放进一个简单的 Mac App 里。

English: A small macOS helper for local Codex/Codex++ provider config, plugin snapshots, mobile host readiness, and session recovery.

## 它能做什么

### 1. 配置自己的 API / 中转站

你可以直接粘贴 API key、Base URL、JSON 或 cURL 示例。App 会自动解析，然后写入 Codex 本地配置，不用再手动打开 `nano` 改 `~/.codex/config.toml`。

它主要处理这些东西：

- `~/.codex/config.toml`
- macOS Keychain
- `launchctl` 环境变量
- Codex++ watcher plist
- `/v1/responses` 测试

### 2. 保留 Codex Mobile

手机端还是正常登录 ChatGPT 账号。这个账号主要用来连接你的 Mac host。

真正的模型请求发生在 Mac 上。只要 Mac 上的 Codex 配置走你的 API，手机连接 Mac host 后，也会走这条本地配置。

注意：

- 手机端要选 **Mac host / local thread**
- 不要选 **Cloud thread**
- Cloud thread 不会读取你 Mac 上的 `~/.codex/config.toml`

### 3. 保存本地插件

如果你已经在 Codex++ 里装好了 Computer Use、Google、Browser 等插件，可以用 HostKit 备份本地插件缓存。以后插件商城不显示时，可以尝试从本地快照恢复。

它会处理：

- `~/.codex/plugins/cache`
- `~/.codex/plugins/local-snapshot`
- `~/.agents/plugins/marketplace.json`

这不等于破解插件商店。它只是保存你自己电脑上已经有的东西。Google、Gmail、Drive 这类插件可能仍然需要重新登录或 OAuth 授权。Computer Use 这类插件可能仍然需要 macOS 屏幕录制和辅助功能权限。

### 4. 找回本地对话

HostKit 可以扫描：

- `~/.codex/sessions`
- `~/.codex/history.jsonl`
- `$CODEX_HOME/sessions`
- `$CODEX_HOME/history.jsonl`

然后帮你搜索本地 sessions、预览对话、导出 Markdown / JSON、备份 sessions，或把过大的 sessions 文件夹移动到 backup。

它不会修改远端 ChatGPT Cloud 历史。它只是帮你找本机还存在的记录。

### 5. 做一些本机检查

比如：

- Codex 配置是否存在
- provider 是否配置正确
- API key 是否保存
- `launchctl` 环境变量是否存在
- Codex++ watcher plist 是否存在
- 插件缓存是否存在
- sessions 是否太大
- app-server 有没有孤立进程
- 9229 端口是否监听

维护页面默认只做诊断。危险操作会生成脚本，让你自己检查后再运行。

## 这个工具不会做什么

Codex HostKit 不会：

- 破解 Codex
- 绕过 ChatGPT / Codex 账号权限
- 下载官方受限插件
- 绕过 Google / Gmail / Drive OAuth
- 替代 Codex 或 Codex++
- 上传你的 API key、sessions 或插件缓存
- 自动杀掉正在运行的 Codex

它只管理你本机已有的配置、缓存和历史。

## 安装

### 方式一：终端下载 DMG

打开 macOS 自带的 `终端`，复制下面命令：

```bash
cd ~/Downloads && \
curl -L -o Codex-HostKit-0.1.0.dmg https://github.com/ZhizhouZhao/Codex-HostKit/releases/download/v0.1.0/Codex-HostKit-0.1.0.dmg && \
echo "3227456bee877710b3245c828addb5f57b5fbde0744024e68811a9c8ce9d8e03  Codex-HostKit-0.1.0.dmg" | shasum -a 256 -c - && \
open Codex-HostKit-0.1.0.dmg
```

命令完成后，会自动打开 DMG。然后把 `Codex HostKit.app` 拖到 `Applications`。

如果校验失败，终端会显示 `FAILED`。这时删除 DMG，重新下载。

### 方式二：从 GitHub Releases 下载

打开 [Releases 页面](https://github.com/ZhizhouZhao/Codex-HostKit/releases)，下载最新的 `.dmg` 文件。

然后：

1. 双击打开 DMG
2. 把 `Codex HostKit.app` 拖到 `Applications`
3. 从 `Applications` 打开 App

### macOS 提示无法打开怎么办

当前版本还没有做 Apple notarization。如果 macOS 提示“无法验证开发者”，可以：

1. 右键点击 `Codex HostKit.app`
2. 选择 `打开`
3. 再次确认打开

或者到：

```text
系统设置 -> 隐私与安全性
```

在底部允许打开。

## 第一次怎么用

### 1. 打开 Provider 配置

粘贴你的中转站信息。可以是 API key：

```text
sk-xxxx
```

也可以是 Base URL：

```text
https://example.com/v1
```

也可以是 JSON：

```json
{"key":"sk-xxxx","url":"https://example.com"}
```

也可以是 cURL：

```bash
curl https://example.com/v1/responses \
  -H "Authorization: Bearer sk-xxxx"
```

然后点击：

```text
解析 Provider 信息
```

确认 base URL、model 和 key 是否识别正确。

### 2. 保存密钥

点击：

```text
保存到 Keychain
```

API key 会保存到 macOS Keychain，不会明文写进 `config.toml`。

### 3. 应用 Codex 配置

点击：

```text
应用 Codex 配置
```

HostKit 会写入：

```text
~/.codex/config.toml
```

写入前会自动备份旧文件。

### 4. 同步环境变量

如果你使用 Codex++ watcher，建议继续点击：

```text
同步到 launchctl
同步到 Watcher
```

这样 Codex++ 接管普通 Codex 后，也能拿到 API key。

### 5. 测试 Provider

点击：

```text
测试 /v1/responses
```

如果返回正常，说明 API 基本可用。如果 provider 后台有请求记录，说明本地请求已经走你的 API / 中转站。

### 6. 手机连接

手机端这样做：

1. 手机和 Mac 登录同一个 ChatGPT 账号
2. 打开手机 ChatGPT
3. 进入 Codex
4. 选择 Mac host / local thread
5. 不要选择 Cloud thread
6. 新建一个 thread
7. 发送 `Reply only ok`
8. 去 provider 后台看有没有请求记录

有请求记录 = 手机只是控制 Mac，模型请求走 Mac 本地 provider。

## 推荐工作流

如果你想用 Codex Mobile，同时让本地请求走自己的 API，可以按这个顺序：

```text
1. Mac 上打开 Codex HostKit
2. 配置 Provider
3. 保存到 Keychain
4. 应用 Codex 配置
5. 同步 launchctl / watcher
6. 打开 Codex / Codex++
7. 手机 ChatGPT 连接 Mac host / local thread
8. 新建 thread 测试
9. 检查 provider dashboard 请求记录
```

不要用 Cloud thread。Cloud thread 不走你的 Mac 本地配置。

## 插件快照

插件快照只处理本机已经存在的插件缓存。

它会扫描：

```text
~/.codex/plugins/cache
```

备份到：

```text
~/.codex/plugins/local-snapshot
```

并生成：

```text
~/.agents/plugins/marketplace.json
```

适合这种情况：

- 你已经装过 Computer Use / Google / Browser 等插件
- 插件商城偶尔不显示
- 不想每次都重新安装插件
- 想保存一份本机快照

不适合这种情况：

- 想下载自己没有权限访问的官方插件
- 想绕过 OAuth
- 想绕过账号或地区的服务端限制

这个工具不会做这些。

## 对话找回

切换账号、provider、Codex++、app-server 后，有时旧 thread 看起来像消失了。

很多时候，本地文件还在。你可以打开 `对话找回` 页面，扫描：

```text
~/.codex/sessions
~/.codex/history.jsonl
```

可以做：

- 搜索
- 预览
- 导出 Markdown
- 导出 JSON
- 备份 sessions
- 移动旧 sessions 到 backup

默认只读。不会改远端 ChatGPT 历史。

## 维护诊断

维护页面会检查：

- app-server 数量
- 是否有孤立 app-server
- sessions 大小
- watcher plist 是否存在
- 9229 是否监听

默认不会自动清理。如果需要清理，会生成脚本，你可以自己看完再运行。

## 从源码运行

### 需要

- macOS 14 或更新
- Xcode 26 或更新
- 已安装 Codex
- 如果你使用 Codex++，需要你自己安装 Codex++

### 克隆仓库

```bash
git clone https://github.com/ZhizhouZhao/Codex-HostKit.git
cd Codex-HostKit
```

### 用 Xcode 打开

```text
打开 CodexPlusPlusCompanion.xcodeproj
选择 CodexPlusPlusCompanion scheme
运行目标选择 My Mac
点击 Run
```

启动后的 App 名称是：

```text
Codex HostKit
```

目前内部 target、bundle id、Keychain service 仍保留历史名称 `CodexPlusPlusCompanion`。这是为了兼容已有本机配置和钥匙串记录。

## 命令行构建

Debug：

```bash
xcodebuild -project CodexPlusPlusCompanion.xcodeproj \
  -scheme CodexPlusPlusCompanion \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

Release：

```bash
xcodebuild -project CodexPlusPlusCompanion.xcodeproj \
  -scheme CodexPlusPlusCompanion \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

构建产物通常在 Xcode DerivedData 里，例如：

```text
~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/Codex HostKit.app
```

## 常见问题

### 手机 Codex Mobile 可以直接填 API key 吗？

不可以。手机端只是连接 Mac。API key 要配置在 Mac 上的 Codex 里。

### 为什么我还要登录 ChatGPT 账号？

因为手机 Codex Mobile 需要用账号找到并连接你的 Mac host。

登录账号不等于一定用账号额度。如果你选择的是 Mac host / local thread，模型请求由 Mac 上的 Codex 配置决定。

### 为什么不能选 Cloud thread？

Cloud thread 是 OpenAI 云端环境。它不会读取你 Mac 上的 `~/.codex/config.toml`。

想走自己的 API，就要选 Mac host / local thread。

### 401 Invalid Token 怎么办？

通常是：

- API key 错了
- key 已失效
- base URL 不对
- Codex++ watcher 拿到了旧 key

先重新在 Provider 页面保存 key。然后同步到 `launchctl` 和 watcher。再测试 `/v1/responses`。

### Missing environment variable 怎么办？

说明 Codex 进程没有拿到 key。可以按顺序做：

1. 保存到 Keychain
2. 同步到 launchctl
3. 同步到 Watcher
4. 重新打开 Codex / Codex++
5. 重新测试

### Idle timeout waiting for SSE 怎么办？

先测试非流式 `/v1/responses`。

如果非流式可以，流式失败，可能是 provider 的 Responses streaming 不稳定，或者服务端超时太短。可以先换更快的模型，并把 reasoning 调低。

### 插件快照能完全代替 VPN 吗？

不能保证。

它可以保存你本机已有的插件文件，减少重复安装。但 Google、Gmail、Drive 这类插件可能仍然需要重新登录或授权。

### 这个项目和 Codex++ 是什么关系？

Codex HostKit 不替代 Codex++。

Codex++ 负责增强 Codex。HostKit 负责帮你管理配置、插件快照、sessions 和手机连接准备。

### 会上传我的 API key 或对话吗？

不会。

HostKit 是本机工具。API key 保存到 macOS Keychain。sessions 扫描和导出都在本机完成。

## 安全说明

- 不要把 API key 发到 issue、截图或日志里。
- 不要提交自己的 `~/.codex` 到 GitHub。
- 不要公开 sessions 导出文件，里面可能有项目路径、代码、命令输出。
- 插件快照可能包含本地插件文件，请自己判断是否适合分享。
- 这个工具不会上传你的 key、插件缓存或 sessions。

## Roadmap

可能会做：

- 更清楚的状态总览
- 导出诊断报告
- 更好的插件快照恢复
- 更好的 App 图标和截图
- 一键生成 repair script
- 更完整的 provider 兼容性测试
- Homebrew Cask
- 签名和 notarization

## 贡献

欢迎提 issue 或 PR。

比较适合贡献的方向：

- 修 README
- 补截图
- 改 UI
- 增加 provider 解析规则
- 改进插件扫描
- 改进 session 解析
- 补更多 troubleshooting

如果你提交 issue，请尽量说明：

- macOS 版本
- Codex / Codex++ 状态
- 你使用的 provider 类型
- 报错信息
- 是否选择了 Mac host / local thread

请不要贴 API key。

## License

MIT License. See [LICENSE](LICENSE).

## About

Codex HostKit 是一个 macOS 本机辅助工具，用来管理 Codex provider 配置、Codex Mobile 本地 host 准备、插件快照、对话找回和维护诊断。
