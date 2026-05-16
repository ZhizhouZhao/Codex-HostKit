import SwiftUI

struct PluginSnapshotView: View {
    @State private var plugins: [PluginInfo] = []
    @State private var log = "点击扫描已安装插件开始。"
    @State private var isWorking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: "插件快照", subtitle: "只备份和恢复这台 Mac 上已经存在的 Codex/Codex++ 插件缓存。")
            Panel {
                HStack {
                    Button("扫描已安装插件") { scan() }.disabled(isWorking)
                    Button("备份插件") { backup() }.disabled(isWorking)
                    Button("恢复插件") { restore() }.disabled(isWorking)
                    Button("生成本地 Marketplace") { marketplace() }.disabled(isWorking)
                    Button("打开插件目录") { PluginSnapshotManager.shared.openPluginFolders() }
                }
                if isWorking {
                    ProgressView().controlSize(.small)
                }
                Text("OAuth 插件可能需要重新授权。Computer Use 仍可能需要 macOS 屏幕录制和辅助功能权限。")
                    .foregroundStyle(.secondary)
            }
            Panel {
                Table(plugins) {
                    TableColumn("名称") { Text($0.name) }
                    TableColumn("Manifest") { Text($0.hasManifest ? "已找到" : "需检查") }
                    TableColumn("版本") { Text($0.version ?? "-") }
                    TableColumn("路径") { Text($0.path.path).textSelection(.enabled) }
                }
                .frame(minHeight: 320)
            }
            Panel {
                Text(log).font(.system(.body, design: .monospaced)).textSelection(.enabled)
            }
        }
        .padding(24)
        .onAppear(perform: scan)
    }

    private func scan() {
        isWorking = true
        log = "正在扫描插件缓存..."
        Task.detached {
            let found = PluginSnapshotManager.shared.scanInstalledPlugins()
            await MainActor.run {
                plugins = found
                log = "找到 \(found.count) 个已安装插件缓存目录。"
                isWorking = false
            }
        }
    }

    private func backup() {
        isWorking = true
        log = "正在备份插件缓存..."
        Task.detached {
            do {
                try PluginSnapshotManager.shared.backupPlugins()
                await MainActor.run {
                    log = "已备份插件缓存到 \(PluginSnapshotManager.shared.snapshotURL.path)。"
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    log = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func restore() {
        isWorking = true
        log = "正在恢复插件快照..."
        Task.detached {
            do {
                try PluginSnapshotManager.shared.restorePlugins()
                let found = PluginSnapshotManager.shared.scanInstalledPlugins()
                await MainActor.run {
                    plugins = found
                    log = "已从本地快照恢复到插件缓存。已有缓存会先移动到带时间戳的备份。"
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    log = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func marketplace() {
        isWorking = true
        log = "正在生成本地 marketplace..."
        Task.detached {
            do {
                try PluginSnapshotManager.shared.generateMarketplace()
                await MainActor.run {
                    log = "已生成 \(PluginSnapshotManager.shared.marketplaceURL.path)。"
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    log = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }
}
