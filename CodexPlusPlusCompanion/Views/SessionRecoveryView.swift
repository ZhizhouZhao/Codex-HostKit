import SwiftUI
import AppKit

struct SessionRecoveryView: View {
    @State private var sessions: [SessionRecord] = []
    @State private var selected: SessionRecord?
    @State private var query = ""
    @State private var projectFilter = "全部"
    @State private var providerFilter = "全部"
    @State private var log = "点击“扫描本地对话”开始。所有内容只在本机读取。"

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
                PageHeader(title: "对话找回", subtitle: "扫描 Mac 本地 Codex sessions，找得到、看得见、能导出、能备份。")
                HStack {
                    Button("扫描本地对话") { scan() }
                    Button("备份 Sessions") { backupSessions() }
                    Button("移动旧/大 Sessions 到备份") { moveOldSessions() }
                }
                TextField("搜索关键词、路径、模型、消息", text: $query)
                    .textFieldStyle(.roundedBorder)
                Picker("项目路径", selection: $projectFilter) {
                    ForEach(projectOptions, id: \.self) { Text($0).tag($0) }
                }
                Picker("Provider", selection: $providerFilter) {
                    ForEach(providerOptions, id: \.self) { Text($0).tag($0) }
                }
                List(filteredSessions, selection: $selected) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.displayTitle)
                            .font(.headline)
                            .lineLimit(2)
                        Text("\(dateText(session.modifiedAt)) · \(session.provider) · \(sizeText(session.fileSize))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !session.projectPath.isEmpty {
                            Text(session.projectPath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                    .tag(session)
                }
                Text(log)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(20)
            .frame(minWidth: 360, idealWidth: 430, maxWidth: 480)
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
                    .padding(24)
                }
            }
            .background(Color.appBackground)
        }
        .onAppear(perform: scan)
    }

    private func detail(for session: SessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 18) {
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
                    Button("导出 Markdown") { exportMarkdown(session) }
                    Button("导出 JSON") { exportJSON(session) }
                    Button("复制 Session ID") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(session.id, forType: .string)
                        log = "已复制 Session ID。"
                    }
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
        .padding(24)
    }

    private func row(_ key: String, _ value: String) -> some View {
        GridRow {
            Text(key).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }

    private func scan() {
        sessions = SessionRecoveryManager.shared.scan()
        selected = selected.flatMap { old in sessions.first { $0.id == old.id && $0.fileURL == old.fileURL } } ?? sessions.first
        log = "已扫描到 \(sessions.count) 个本地 session/history 文件。"
    }

    private func exportMarkdown(_ session: SessionRecord) {
        do {
            let url = try SessionRecoveryManager.shared.exportMarkdown(session)
            log = "已导出 Markdown：\(url.path)"
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            log = error.localizedDescription
        }
    }

    private func exportJSON(_ session: SessionRecord) {
        do {
            let url = try SessionRecoveryManager.shared.exportJSON(session)
            log = "已导出 JSON：\(url.path)"
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            log = error.localizedDescription
        }
    }

    private func backupSessions() {
        do {
            let backups = try SessionRecoveryManager.shared.backupAllSessions()
            log = backups.isEmpty ? "没有找到可备份的 sessions 目录。" : "已备份：\n" + backups.map(\.path).joined(separator: "\n")
        } catch {
            log = error.localizedDescription
        }
    }

    private func moveOldSessions() {
        do {
            let backup = try SessionRecoveryManager.shared.moveOldOrLargeSessionsToBackup()
            log = "已将 30 天前或超过 25 MB 的 session 文件移动到备份：\(backup.path)"
            scan()
        } catch {
            log = error.localizedDescription
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
