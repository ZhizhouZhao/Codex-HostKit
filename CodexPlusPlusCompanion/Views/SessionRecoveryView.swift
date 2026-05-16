import SwiftUI
import AppKit

struct SessionRecoveryView: View {
    @EnvironmentObject private var notifier: AppNotifier
    @State private var sessions: [SessionRecord] = []
    @State private var selected: SessionRecord?
    @State private var query = ""
    @State private var projectFilter = "全部"
    @State private var providerFilter = "全部"
    @State private var log = "点击“扫描本地对话”开始。所有内容只在本机读取。"
    @State private var isWorking = false

    private var filteredSessions: [SessionRecord] {
        sessions.filter { session in
            let haystack = [
                session.id,
                session.threadID,
                session.projectPath,
                session.provider,
                session.model,
                session.firstUserMessage,
                session.lastAssistantMessage,
                session.fileURL.path
            ].joined(separator: " ").lowercased()
            let matchesQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || haystack.contains(query.lowercased())
            let matchesProject = projectFilter == "全部" || session.projectPath == projectFilter
            let matchesProvider = providerFilter == "全部" || session.provider == providerFilter
            return matchesQuery && matchesProject && matchesProvider
        }
    }

    private var projectOptions: [String] {
        ["全部"] + Array(Set(sessions.map(\.projectPath).filter { !$0.isEmpty })).sorted()
    }

    private var providerOptions: [String] {
        ["全部"] + Array(Set(sessions.map(\.provider).filter { !$0.isEmpty })).sorted()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                PageHeader(title: "对话找回", subtitle: "扫描本机历史，找回、预览、导出和备份本地对话。")
                ViewThatFits(in: .horizontal) {
                    HStack {
                        rescueButtons
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        rescueButtons
                    }
                }
                .font(.caption)
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                }
                TextField("搜索关键词、路径、模型、消息", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .help("在本地 session 列表里搜索。不会上传内容。")
                Picker("项目", selection: $projectFilter) {
                    ForEach(projectOptions, id: \.self) { Text($0).tag($0) }
                }
                .help("项目路径是当时运行 Codex 的文件夹位置。")
                Picker("Provider", selection: $providerFilter) {
                    ForEach(providerOptions, id: \.self) { Text($0).tag($0) }
                }
                .help("Provider 是当时使用的模型服务提供方，例如 OpenAI、KKRICH、custom。")
                List(filteredSessions, selection: $selected) { session in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.displayTitle)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                        Text("\(dateText(session.modifiedAt)) · \(session.provider) · \(sizeText(session.fileSize))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if !session.projectPath.isEmpty {
                            Text(session.projectPath)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                    .tag(session)
                }
                Text(log)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(14)
            .frame(minWidth: 270, idealWidth: 330, maxWidth: 400)
            .background(Color.appBackground)

            Divider().opacity(0.35)

            ScrollView {
                if let selected {
                    detail(for: selected)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        PageHeader(title: "Session 详情", subtitle: "从左侧选择一个本地 session。")
                        Panel {
                            Text("不会上传任何 session 内容；预览和导出都在本地完成。")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color.appBackground)
        }
        .onAppear(perform: scan)
    }

    private var rescueButtons: some View {
        Group {
                    Button("扫描本地对话") { scan() }.disabled(isWorking)
                .help("重新扫描 ~/.codex/sessions 和 history.jsonl，只在本机读取。")
                    Button("备份 Sessions") { backupSessions() }.disabled(isWorking)
                .help("Sessions 是 Codex 本地对话文件夹。备份会复制整个目录，不删除原文件。")
                    Button("移动旧/大 Sessions 到备份") { moveOldSessions() }.disabled(isWorking)
                .help("只移动 30 天前或超过 25 MB 的文件到备份目录，不会直接删除。")
        }
    }

    private func detail(for session: SessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PageHeader(title: "Session 详情", subtitle: session.id)
            Panel {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    row("Session ID", session.id)
                    row("Thread ID", session.threadID.isEmpty ? "未找到" : session.threadID)
                    row("创建时间", dateText(session.createdAt))
                    row("最后更新", dateText(session.modifiedAt))
                    row("项目路径", session.projectPath.isEmpty ? "未知" : session.projectPath)
                    row("模型", session.model.isEmpty ? "未知" : session.model)
                    row("Provider", session.provider)
                    row("文件大小", sizeText(session.fileSize))
                    row("文件路径", session.fileURL.path)
                }
            }
            Panel {
                Text("第一条用户消息").font(.headline)
                Text(session.firstUserMessage.isEmpty ? "未解析到" : session.firstUserMessage)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text("最后一条助手回复").font(.headline)
                Text(session.lastAssistantMessage.isEmpty ? "未解析到" : session.lastAssistantMessage)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Panel {
                HStack {
                    Button("在 Finder 打开") { SessionRecoveryManager.shared.openInFinder(session) }
                        .help("Finder 是 macOS 文件管理器。这里会定位到该 session 文件。")
                    Button("导出 Markdown") { exportMarkdown(session) }.disabled(isWorking)
                        .help("Markdown 是适合阅读和分享的文本格式，扩展名 .md。")
                    Button("导出 JSON") { exportJSON(session) }.disabled(isWorking)
                        .help("JSON 是结构化数据格式，适合后续程序处理或排查问题。")
                    Button("复制 Session ID") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(session.id, forType: .string)
                        log = "已复制 Session ID。"
                        notifier.success("复制成功", detail: "Session ID 已复制到剪贴板。")
                    }
                    .help("Session ID 是本地对话文件的识别编号。")
                }
                Text("导出前请注意：session 可能包含代码、路径、命令输出和项目隐私。App 会做基础脱敏，但请在分享前自行复查。")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
            Panel {
                Text("脱敏预览").font(.headline)
                Text(session.previewText.isEmpty ? "文件为空或无法读取。" : session.previewText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }

    private func row(_ key: String, _ value: String) -> some View {
        GridRow {
            Text(key).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }

    private func scan() {
        isWorking = true
        log = "正在后台扫描本地 sessions..."
        let previous = selected
        Task.detached {
            let records = SessionRecoveryManager.shared.scan()
            await MainActor.run {
                sessions = records
                selected = previous.flatMap { old in records.first { $0.id == old.id && $0.fileURL == old.fileURL } } ?? records.first
                log = "已扫描到 \(records.count) 个本地 session/history 文件。"
                isWorking = false
                notifier.success("扫描成功", detail: "已找到 \(records.count) 个本地对话文件。")
            }
        }
    }

    private func exportMarkdown(_ session: SessionRecord) {
        isWorking = true
        log = "正在导出 Markdown..."
        Task.detached {
            do {
                let url = try SessionRecoveryManager.shared.exportMarkdown(session)
                await MainActor.run {
                    log = "已导出 Markdown：\(url.path)"
                    isWorking = false
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    notifier.success("导出成功", detail: "Markdown 文件已保存到 Downloads。")
                }
            } catch {
                await MainActor.run {
                    log = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func exportJSON(_ session: SessionRecord) {
        isWorking = true
        log = "正在导出 JSON..."
        Task.detached {
            do {
                let url = try SessionRecoveryManager.shared.exportJSON(session)
                await MainActor.run {
                    log = "已导出 JSON：\(url.path)"
                    isWorking = false
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    notifier.success("导出成功", detail: "JSON 文件已保存到 Downloads。")
                }
            } catch {
                await MainActor.run {
                    log = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func backupSessions() {
        isWorking = true
        log = "正在后台备份 sessions..."
        Task.detached {
            do {
                let backups = try SessionRecoveryManager.shared.backupAllSessions()
                await MainActor.run {
                    log = backups.isEmpty ? "没有找到可备份的 sessions 目录。" : "已备份：\n" + backups.map(\.path).joined(separator: "\n")
                    isWorking = false
                    if !backups.isEmpty {
                        notifier.success("备份成功", detail: "Sessions 目录已复制到备份位置。")
                    }
                }
            } catch {
                await MainActor.run {
                    log = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func moveOldSessions() {
        isWorking = true
        log = "正在移动旧/大 session 文件到备份..."
        Task.detached {
            do {
                let backup = try SessionRecoveryManager.shared.moveOldOrLargeSessionsToBackup()
                let records = SessionRecoveryManager.shared.scan()
                await MainActor.run {
                    sessions = records
                    selected = records.first
                    log = "已将 30 天前或超过 25 MB 的 session 文件移动到备份：\(backup.path)"
                    isWorking = false
                    notifier.success("移动成功", detail: "旧/大 session 文件已移动到备份目录。")
                }
            } catch {
                await MainActor.run {
                    log = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else { return "未知" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func sizeText(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
