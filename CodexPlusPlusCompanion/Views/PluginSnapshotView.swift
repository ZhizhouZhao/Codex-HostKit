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
                VStack(alignment: .leading, spacing: 10) {
                    Text("只备份本机已有插件缓存，不下载插件，也不绕过官方权限。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    ViewThatFits(in: .horizontal) {
                        pluginToolbar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { scanButton; backupButton; restoreButton }
                            HStack { marketplaceButton; openFolderButton; workingIndicator }
                        }
                    }
                }
            }
            Panel {
                PluginListView(plugins: plugins, isWorking: isWorking)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
            Panel {
                Text(log)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: scan)
    }

    private var pluginToolbar: some View {
        HStack {
            scanButton
            backupButton
            restoreButton
            marketplaceButton
            openFolderButton
            workingIndicator
        }
    }

    private var scanButton: some View {
        Button("扫描已安装插件") { scan() }
            .disabled(isWorking)
            .help("扫描本机已经存在的插件缓存，不会下载插件。")
    }

    private var backupButton: some View {
        Button("备份插件") { backup() }
            .disabled(isWorking)
            .help("把本机插件缓存复制到 local-snapshot，恢复时可从这里取回。")
    }

    private var restoreButton: some View {
        Button("恢复插件") { restore() }
            .disabled(isWorking)
            .help("从 local-snapshot 恢复到插件缓存；已有缓存会先移动到备份。")
    }

    private var marketplaceButton: some View {
        Button("生成本地 Marketplace") { marketplace() }
            .disabled(isWorking)
            .help("Marketplace 是插件列表文件。这里生成的是只指向本机快照的个人列表。")
    }

    private var openFolderButton: some View {
        Button("打开插件目录") { PluginSnapshotManager.shared.openPluginFolders() }
            .help("在 Finder 中打开插件相关文件夹。")
    }

    @ViewBuilder
    private var workingIndicator: some View {
        if isWorking {
            ProgressView().controlSize(.small)
        }
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

struct PluginListView: View {
    let plugins: [PluginInfo]
    let isWorking: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if plugins.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(isWorking ? "正在扫描插件缓存..." : "没有扫描到插件缓存", systemImage: isWorking ? "hourglass" : "tray")
                            .font(.headline)
                        Text(isWorking ? "请稍等，App 正在读取本机 ~/.codex/plugins/cache。" : "可以点击“打开插件目录”确认本机是否已有缓存，或先在 Codex 中安装/启用插件后再扫描。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 280, alignment: .center)
                } else {
                    HStack(spacing: 12) {
                        Text("插件").frame(maxWidth: .infinity, alignment: .leading)
                        Text("版本").frame(width: 120, alignment: .leading)
                        Text("分类").frame(width: 120, alignment: .leading)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)

                    ForEach(plugins) { plugin in
                        PluginRowView(plugin: plugin)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

struct PluginRowView: View {
    let plugin: PluginInfo

    var body: some View {
        HStack(spacing: 12) {
            PluginIdentityView(plugin: plugin)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(plugin.version ?? "-")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(plugin.category ?? "-")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08))
        )
        .help(plugin.path.path)
    }
}

struct PluginIdentityView: View {
    let plugin: PluginInfo

    var body: some View {
        HStack(spacing: 10) {
            PluginIconView(plugin: plugin)
            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.displayName)
                    .font(.headline)
                    .lineLimit(1)
                if plugin.displayName != plugin.name {
                    Text(plugin.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PluginIconView: View {
    let plugin: PluginInfo
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(plugin.brandColor.flatMap(Color.init(hex:)) ?? Color.white.opacity(0.10))
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(5)
            } else {
                Image(systemName: "puzzlepiece.extension.fill")
                    .foregroundStyle(.white.opacity(0.85))
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.12))
        )
        .task(id: plugin.iconURL) {
            guard let iconURL = plugin.iconURL else { return }
            let loaded = await Task.detached(priority: .utility) {
                NSImage(contentsOf: iconURL)
            }.value
            image = loaded
        }
    }
}

private extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            return nil
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}
