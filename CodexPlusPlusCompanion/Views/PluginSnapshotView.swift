import SwiftUI

struct PluginSnapshotView: View {
    @EnvironmentObject private var notifier: AppNotifier
    @State private var plugins: [PluginInfo] = []
    @State private var log = "点击扫描已安装插件开始。"
    @State private var isWorking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PageHeader(title: "插件快照", subtitle: "备份本机已有插件缓存，减少网络切换后插件入口丢失的麻烦。")
            Panel {
                InfoBlock(
                    title: "为什么需要本地插件快照",
                    text: "部分地区插件库显示不完整，或者不挂 VPN 时商店内容加载不稳定。这个功能只保存你这台 Mac 已经安装过的插件缓存，之后可从本地恢复，避免反复依赖插件商店加载。OAuth 授权和官方权限仍以服务端为准。",
                    icon: "shippingbox"
                )
            }
            Panel {
                HStack {
                    Button("扫描已安装插件") { scan() }.disabled(isWorking)
                        .help("扫描本机已经存在的插件缓存，不会下载插件。")
                    Button("备份插件") { backup() }.disabled(isWorking)
                        .help("把本机插件缓存复制到 local-snapshot，恢复时可从这里取回。")
                    Button("恢复插件") { restore() }.disabled(isWorking)
                        .help("从 local-snapshot 恢复到插件缓存；已有缓存会先移动到备份。")
                    Button("生成本地 Marketplace") { marketplace() }.disabled(isWorking)
                        .help("Marketplace 是插件列表文件。这里生成的是只指向本机快照的个人列表。")
                    Button("打开插件目录") { PluginSnapshotManager.shared.openPluginFolders() }
                        .help("在 Finder 中打开插件相关文件夹。")
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
        .padding(16)
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
                notifier.success("扫描成功", detail: "找到 \(found.count) 个插件缓存目录。")
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
                    notifier.success("备份成功", detail: "插件缓存已保存为本地快照。")
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
                    notifier.success("恢复成功", detail: "插件缓存已从本地快照恢复。")
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
                    notifier.success("生成成功", detail: "本地 Marketplace 文件已更新。")
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
