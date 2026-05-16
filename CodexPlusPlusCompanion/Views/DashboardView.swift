import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var notifier: AppNotifier
    @State private var statuses: [HealthStatus] = []
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                PageHeader(title: "总览", subtitle: "检查本机 Codex++ host、provider bridge 和插件状态。")
                Panel {
                    Button(isRefreshing ? "正在刷新..." : "刷新状态") { refresh() }
                        .disabled(isRefreshing)
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
                Panel {
                    Text("手机连接提醒").font(.headline)
                    Text("手机 ChatGPT 仍然需要登录账号。Codex Mobile 必须选择 Mac host / local thread，不要选择 Cloud thread，本地 provider 计费才会生效。")
                        .foregroundStyle(.secondary)
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
            HealthStatus(title: "Codex++ watcher plist", detail: watcher.plistURL.path, level: watcher.exists() ? .ok : .warning),
            HealthStatus(title: "Watcher EnvironmentVariables", detail: watcher.hasEnvironmentVariables() ? "已配置" : "缺失", level: watcher.hasEnvironmentVariables() ? .ok : .warning),
            HealthStatus(title: "Sessions 大小", detail: sessionsSize, level: .ok),
            HealthStatus(title: "插件缓存", detail: plugin.cacheURL.path, level: plugin.cacheExists() ? .ok : .warning),
            HealthStatus(title: "本地 marketplace", detail: plugin.marketplaceURL.path, level: plugin.marketplaceExists() ? .ok : .warning)
        ]
    }
}
