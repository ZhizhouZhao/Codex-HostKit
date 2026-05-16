import SwiftUI

struct PluginSnapshotView: View {
    @State private var plugins: [PluginInfo] = []
    @State private var log = "点击扫描已安装插件开始。"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: "插件快照", subtitle: "只备份和恢复这台 Mac 上已经存在的 Codex/Codex++ 插件缓存。")
            Panel {
                HStack {
                    Button("扫描已安装插件") { scan() }
                    Button("备份插件") { backup() }
                    Button("恢复插件") { restore() }
                    Button("生成本地 Marketplace") { marketplace() }
                    Button("打开插件目录") { PluginSnapshotManager.shared.openPluginFolders() }
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
        plugins = PluginSnapshotManager.shared.scanInstalledPlugins()
        log = "找到 \(plugins.count) 个已安装插件缓存目录。"
    }

    private func backup() {
        do {
            try PluginSnapshotManager.shared.backupPlugins()
            log = "已备份插件缓存到 \(PluginSnapshotManager.shared.snapshotURL.path)。"
        } catch {
            log = error.localizedDescription
        }
    }

    private func restore() {
        do {
            try PluginSnapshotManager.shared.restorePlugins()
            log = "已从本地快照恢复到插件缓存。已有缓存会先移动到带时间戳的备份。"
            scan()
        } catch {
            log = error.localizedDescription
        }
    }

    private func marketplace() {
        do {
            try PluginSnapshotManager.shared.generateMarketplace()
            log = "已生成 \(PluginSnapshotManager.shared.marketplaceURL.path)。"
        } catch {
            log = error.localizedDescription
        }
    }
}
