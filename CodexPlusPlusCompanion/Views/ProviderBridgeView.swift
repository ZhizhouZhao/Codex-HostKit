import SwiftUI

struct ProviderBridgeView: View {
    @EnvironmentObject private var notifier: AppNotifier
    @State private var pastedText = ""
    @State private var provider = ProviderConfig()
    @State private var log = "粘贴 provider 信息，然后点击解析。"
    @State private var isTesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                PageHeader(title: "Provider 配置", subtitle: "让 Mac 本地 Codex 请求走中转站 / OpenAI-compatible API，而不是消耗 ChatGPT Cloud 额度。")
                Panel {
                    InfoBlock(
                        title: "这里配置的是实际模型请求的计费方",
                        text: "ChatGPT 登录只用于手机扫码和 Mac host 连接；本机 Codex 的模型请求会读取 ~/.codex/config.toml 和环境变量。你在这里粘贴中转站链接、API key、JSON 或 cURL，App 会帮你解析、保存 key、备份并写入配置。",
                        icon: "network"
                    )
                }
                Panel {
                    Text("Provider 输入").font(.headline)
                        .help("Provider 指模型服务提供方，也就是你的请求实际发往哪里计费。可以是 OpenAI，也可以是兼容 OpenAI API 的中转站。")
                    TextEditor(text: $pastedText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 105)
                        .scrollContentBackground(.hidden)
                        .background(Color.black.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button("解析 Provider 信息") { parse() }
                            .help("从粘贴内容里识别 API key、接口地址、模型名。支持 key、URL、JSON、cURL。")
                        Button("保存到 Keychain") { saveKeychain() }.disabled(provider.apiKey.isEmpty)
                            .help("Keychain 是 macOS 系统钥匙串，用来安全保存密码和 API key，避免明文写进日志。")
                        Button("应用 Codex 配置") { applyConfig() }.disabled(provider.baseURL.isEmpty)
                            .help("写入 ~/.codex/config.toml。写入前会自动备份旧文件。")
                    }
                    HStack {
                        Button("同步到 launchctl") { syncLaunchctl() }.disabled(provider.apiKey.isEmpty)
                            .help("launchctl 是 macOS 的后台环境变量管理工具。同步后，之后启动的本机 Codex 进程能读到 API key。")
                        Button("同步到 Codex++ Watcher") { syncWatcher() }.disabled(provider.apiKey.isEmpty)
                            .help("Watcher 是 Codex++ 的本地监控启动配置。这里会把 API key 写入它的 EnvironmentVariables，并先备份 plist。")
                        Button("测试 /v1/responses 非流式") { testProvider() }.disabled(provider.apiKey.isEmpty || provider.baseURL.isEmpty || isTesting)
                            .help("向 provider 发一条最小测试请求，确认接口地址和 API key 能用。")
                        Button("测试 /v1/responses 流式") { log = "流式测试在当前 MVP 中暂未完整实现。" }
                            .help("流式就是边生成边返回。当前版本先提供非流式稳定测试。")
                    }
                }
                Panel {
                    Text("解析结果").font(.headline)
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                        row("Provider", provider.providerName)
                        row("Base URL", provider.baseURL.isEmpty ? "Missing" : provider.baseURL)
                        row("Model", provider.model)
                        row("API key", provider.redactedKey)
                    }
                }
                Panel {
                    Text("输出").font(.headline)
                    Text(log)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .padding(.trailing, 4)
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        GridRow {
            Text(key).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }

    private func parse() {
        provider = ProviderParser.parse(pastedText)
        log = "已解析 provider 信息。API key：\(provider.apiKey.isEmpty ? "缺失" : "已识别")；base URL：\(provider.baseURL.isEmpty ? "缺失" : provider.baseURL)。"
        if !provider.apiKey.isEmpty || !provider.baseURL.isEmpty {
            notifier.success("解析成功", detail: "已识别 Provider 信息。")
        }
    }

    private func saveKeychain() {
        do {
            try KeychainManager.saveAPIKey(provider.apiKey)
            log = "已将 API key 保存到 Keychain service：\(KeychainManager.service)。"
            notifier.success("保存成功", detail: "API key 已安全保存到 macOS Keychain。")
        } catch {
            log = error.localizedDescription
        }
    }

    private func applyConfig() {
        do {
            let backup = try ConfigManager.shared.writeProviderConfig(provider)
            log = "已写入 config.toml。备份：\(backup?.path ?? "无，创建了新文件")。"
            notifier.success("配置成功", detail: "已应用 Codex provider 配置，并完成备份。")
        } catch {
            log = error.localizedDescription
        }
    }

    private func syncLaunchctl() {
        do {
            try LaunchctlManager.setProviderEnvironment(apiKey: provider.apiKey)
            log = "已同步 OPENAI_API_KEY 和 KKRICH_API_KEY 到 launchctl。不会打印 key 明文。"
            notifier.success("同步成功", detail: "环境变量已同步到 launchctl。")
        } catch {
            log = error.localizedDescription
        }
    }

    private func syncWatcher() {
        do {
            guard WatcherPlistManager.shared.exists() else {
                log = "未找到 watcher plist：\(WatcherPlistManager.shared.plistURL.path)"
                return
            }
            let backup = try WatcherPlistManager.shared.updateEnvironment(apiKey: provider.apiKey)
            log = "已更新 watcher EnvironmentVariables。备份：\(backup?.path ?? "无")。"
            notifier.success("同步成功", detail: "Codex++ Watcher 环境变量已更新。")
        } catch {
            log = error.localizedDescription
        }
    }

    private func testProvider() {
        isTesting = true
        Task {
            let result = await ProviderTester.testResponses(config: provider)
            await MainActor.run {
                log = result
                isTesting = false
                if result.contains("HTTP 2") {
                    notifier.success("测试成功", detail: "Provider /v1/responses 已返回成功状态。")
                }
            }
        }
    }
}
