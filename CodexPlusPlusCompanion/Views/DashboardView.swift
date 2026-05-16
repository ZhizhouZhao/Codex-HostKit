import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var notifier: AppNotifier
    @State private var statuses: [HealthStatus] = []
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                PageHeader(title: "Codex Mobile + ChatGPT 登录，但 API 走中转计费", subtitle: "保持手机和 Mac 账号登录可连接，同时让本机 Codex 请求使用 OpenAI-compatible provider。")
                Panel {
                    InfoBlock(
                        title: "这个 App 解决什么痛点",
                        text: "手机 Codex Mobile 本来要求手机 ChatGPT 和 Mac 端 Codex GUI 登录同一个账号，用来扫码连接 Mac host。但普通 Plus 套餐额度不够用，Pro 又不一定划算。本工具帮助你保留 ChatGPT 登录和扫码连接，同时把 Mac 本地真实模型请求配置到中转站或其他 OpenAI-compatible API。",
                        icon: "iphone.gen3"
                    )
                    Divider().opacity(0.25)
                    InfoBlock(
                        title: "为什么需要对话找回",
                        text: "你在 ChatGPT 登录模式、本地 API provider、watcher 或 app-server 之间切换时，本地 thread 可能看起来丢了、列表不完整，或者手机重连后看不到旧对话。对话找回只扫描本机 sessions，帮你找到、预览、导出和备份本地历史。",
                        icon: "clock.arrow.circlepath"
                    )
                    Divider().opacity(0.25)
                    InfoBlock(
                        title: "为什么要插件快照",
                        text: "部分地区插件库显示不完整，之前已经安装过的插件也可能因为网络环境变化而不显示。本地插件快照只备份你这台 Mac 上已有的插件缓存，减少重复挂 VPN 找回插件入口的麻烦，不下载或解锁官方受限插件。",
                        icon: "shippingbox"
                    )
                }
                Panel {
                    Text("推荐操作顺序").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                        quickStep("1. 确认本机 Codex", "确认 Mac 端能打开并可扫码连接。", "arrow.down.circle")
                        quickStep("2. 配置 Provider", "粘贴中转站 URL / API key。", "network")
                        quickStep("3. 手机扫码连接", "手机和 Mac 保持 ChatGPT 登录。", "qrcode")
                        quickStep("4. 检查请求记录", "确认消耗的是 provider 额度。", "checkmark.seal")
                    }
                    HStack {
                        CompactLinkButton(
                            title: "Codex++ 软件页面",
                            systemImage: "arrow.up.right.square",
                            url: URL(string: "https://github.com/bigpizzav3/codex-plus-plus")!
                        )
                        .help("由国内开发者开发的 Codex++ 可以实现 API 登录、解锁插件功能。")
                        Button("刷新状态") { refresh() }
                            .disabled(isRefreshing)
                            .help("重新检查配置、Keychain、watcher、sessions、插件缓存等本机状态。")
                    }
                }
                Panel {
                    Text("当前状态").font(.headline)
                    VStack(spacing: 10) {
                        ForEach(statuses) { status in
                            HStack(alignment: .top, spacing: 12) {
                                Circle().fill(status.level.color).frame(width: 10, height: 10).padding(.top, 5)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(status.title).font(.headline)
                                    Text(status.detail).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(status.level.rawValue).foregroundStyle(status.level.color)
                            }
                            Divider().opacity(0.25)
                        }
                    }
                }
            }
            .padding(16)
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        isRefreshing = true
        Task.detached {
            let statuses = DashboardStatusBuilder.build()
            await MainActor.run {
                self.statuses = statuses
                self.isRefreshing = false
                self.notifier.success("刷新成功", detail: "总览状态已更新。")
            }
        }
    }
}

private func quickStep(_ title: String, _ text: String, _ icon: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
        Image(systemName: icon)
            .foregroundStyle(.green)
            .frame(width: 18)
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
    }
    .padding(10)
    .background(Color.black.opacity(0.16))
    .clipShape(RoundedRectangle(cornerRadius: 8))
}

enum DashboardStatusBuilder {
    static func build() -> [HealthStatus] {
        let config = ConfigManager.shared
        let summary = config.summary()
        let baseURL = summary["base_url"] ?? ""
        let provider = summary["model_provider"] ?? ""
        let keychainKey = (try? KeychainManager.loadAPIKey()) ?? nil
        let launchKey = LaunchctlManager.getenv("OPENAI_API_KEY")
        let sessionsSize = config.formattedSize(config.directorySize(config.sessionsURL))
        let plugin = PluginSnapshotManager.shared
        let watcher = WatcherPlistManager.shared

        return [
            HealthStatus(title: "Codex config", detail: config.configURL.path, level: config.configExists() ? .ok : .error),
            HealthStatus(title: "当前 provider", detail: provider.isEmpty ? "未找到 model_provider" : provider, level: provider == "custom" || provider == "kkrich" ? .ok : .warning),
            HealthStatus(title: "Base URL", detail: baseURL.isEmpty ? "缺少 base_url" : baseURL, level: baseURL.hasPrefix("http") ? .ok : .warning),
            HealthStatus(title: "API key", detail: keychainKey != nil ? "已存入 Keychain" : (launchKey != nil ? "launchctl 中存在" : "缺失"), level: (keychainKey != nil || launchKey != nil) ? .ok : .warning),
            HealthStatus(title: "Watcher plist", detail: watcher.plistURL.path, level: watcher.exists() ? .ok : .warning),
            HealthStatus(title: "Watcher EnvironmentVariables", detail: watcher.hasEnvironmentVariables() ? "已配置" : "缺失", level: watcher.hasEnvironmentVariables() ? .ok : .warning),
            HealthStatus(title: "Sessions 大小", detail: sessionsSize, level: .ok),
            HealthStatus(title: "插件缓存", detail: plugin.cacheURL.path, level: plugin.cacheExists() ? .ok : .warning),
            HealthStatus(title: "本地 marketplace", detail: plugin.marketplaceURL.path, level: plugin.marketplaceExists() ? .ok : .warning)
        ]
    }
}
