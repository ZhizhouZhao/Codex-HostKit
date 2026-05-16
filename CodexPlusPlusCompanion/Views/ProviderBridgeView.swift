import SwiftUI

struct ProviderBridgeView: View {
    @State private var pastedText = ""
    @State private var provider = ProviderConfig()
    @State private var log = "粘贴 provider 信息，然后点击解析。"
    @State private var isTesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Provider 配置", subtitle: "粘贴 OpenAI-compatible provider 信息，自动写入本地 Codex 配置。")
                Panel {
                    Text("Provider 输入").font(.headline)
                    TextEditor(text: $pastedText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .background(Color.black.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button("解析 Provider 信息") { parse() }
                        Button("保存到 Keychain") { saveKeychain() }.disabled(provider.apiKey.isEmpty)
                        Button("应用 Codex 配置") { applyConfig() }.disabled(provider.baseURL.isEmpty)
                    }
                    HStack {
                        Button("同步到 launchctl") { syncLaunchctl() }.disabled(provider.apiKey.isEmpty)
                        Button("同步到 Codex++ Watcher") { syncWatcher() }.disabled(provider.apiKey.isEmpty)
                        Button("测试 /v1/responses 非流式") { testProvider() }.disabled(provider.apiKey.isEmpty || provider.baseURL.isEmpty || isTesting)
                        Button("测试 /v1/responses 流式") { log = "流式测试在当前 MVP 中暂未完整实现。" }
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
            .padding(24)
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
    }

    private func saveKeychain() {
        do {
            try KeychainManager.saveAPIKey(provider.apiKey)
            log = "已将 API key 保存到 Keychain service：\(KeychainManager.service)。"
        } catch {
            log = error.localizedDescription
        }
    }

    private func applyConfig() {
        do {
            let backup = try ConfigManager.shared.writeProviderConfig(provider)
            log = "已写入 config.toml。备份：\(backup?.path ?? "无，创建了新文件")。"
        } catch {
            log = error.localizedDescription
        }
    }

    private func syncLaunchctl() {
        do {
            try LaunchctlManager.setProviderEnvironment(apiKey: provider.apiKey)
            log = "已同步 OPENAI_API_KEY 和 KKRICH_API_KEY 到 launchctl。不会打印 key 明文。"
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
            }
        }
    }
}
