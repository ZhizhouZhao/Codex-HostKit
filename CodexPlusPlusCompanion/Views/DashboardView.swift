import SwiftUI

struct DashboardView: View {
    @State private var statuses: [HealthStatus] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Dashboard", subtitle: "Local Codex++ host readiness and provider bridge status.")
                Panel {
                    Button("Refresh Status") { refresh() }
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
                    Text("Mobile reminder").font(.headline)
                    Text("ChatGPT login is still needed on the phone. Codex Mobile must choose Mac host / local thread, not Cloud thread, for local provider billing.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        let config = ConfigManager.shared
        let summary = config.summary()
        let baseURL = summary["base_url"] ?? ""
        let provider = summary["model_provider"] ?? ""
        let keychainKey = (try? KeychainManager.loadAPIKey()) ?? nil
        let launchKey = LaunchctlManager.getenv("OPENAI_API_KEY")
        let sessionsSize = config.formattedSize(config.directorySize(config.sessionsURL))
        let plugin = PluginSnapshotManager.shared
        let watcher = WatcherPlistManager.shared

        statuses = [
            HealthStatus(title: "Codex config", detail: config.configURL.path, level: config.configExists() ? .ok : .error),
            HealthStatus(title: "Current provider", detail: provider.isEmpty ? "No model_provider found" : provider, level: provider == "custom" || provider == "kkrich" ? .ok : .warning),
            HealthStatus(title: "Base URL", detail: baseURL.isEmpty ? "Missing base_url" : baseURL, level: baseURL.hasPrefix("http") ? .ok : .warning),
            HealthStatus(title: "API key", detail: keychainKey != nil ? "Stored in Keychain" : (launchKey != nil ? "Available in launchctl" : "Missing"), level: (keychainKey != nil || launchKey != nil) ? .ok : .warning),
            HealthStatus(title: "Codex++ watcher plist", detail: watcher.plistURL.path, level: watcher.exists() ? .ok : .warning),
            HealthStatus(title: "Watcher EnvironmentVariables", detail: watcher.hasEnvironmentVariables() ? "Present" : "Missing", level: watcher.hasEnvironmentVariables() ? .ok : .warning),
            HealthStatus(title: "Sessions size", detail: sessionsSize, level: .ok),
            HealthStatus(title: "Plugin cache", detail: plugin.cacheURL.path, level: plugin.cacheExists() ? .ok : .warning),
            HealthStatus(title: "Local marketplace", detail: plugin.marketplaceURL.path, level: plugin.marketplaceExists() ? .ok : .warning)
        ]
    }
}
