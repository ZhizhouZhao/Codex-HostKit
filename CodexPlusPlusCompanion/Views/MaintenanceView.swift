import SwiftUI

struct MaintenanceView: View {
    @EnvironmentObject private var notifier: AppNotifier
    @State private var report = MaintenanceReport()
    @State private var output = "点击“仅诊断”。"
    @State private var isWorking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                PageHeader(title: "维护诊断", subtitle: "先做只读诊断。脚本只生成给用户确认，不自动执行。")
                Panel {
                    HStack {
                        Button("仅诊断") { diagnose() }.disabled(isWorking)
                            .help("只读取进程和文件状态，不修改任何内容。")
                        Button("生成清理孤儿进程脚本") { output = ProcessInspector.cleanOrphanScript() }
                            .help("只生成脚本文本，不自动执行。孤儿进程是父进程已退出但还残留的 app-server。")
                        Button("生成修复脚本") { output = ProcessInspector.repairScript() }
                            .help("只生成脚本文本，用于手动重载 Codex++ watcher。")
                        Button("备份 Sessions") { backupSessions() }.disabled(isWorking)
                            .help("复制本地对话目录作为备份。")
                        Button("移动旧 Sessions 到备份") { resetSessions() }.disabled(isWorking)
                            .help("把当前 sessions 文件夹移动到备份位置，然后创建新的空 sessions 文件夹。不会删除。")
                    }
                    if isWorking {
                        ProgressView().controlSize(.small)
                    }
                }
                Panel {
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                        row("app-server 进程数", "\(report.appServerCount)")
                        row("PPID=1 孤儿 app-server", "\(report.orphanAppServerCount)")
                        row("sessions 大小", report.sessionsSize)
                        row("watcher plist", report.watcherExists ? "存在" : "缺失")
                        row("9229 是否监听", report.port9229Listening ? "是" : "否")
                    }
                }
                Panel {
                    Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
            }
            .padding(16)
        }
        .onAppear(perform: diagnose)
    }

    private func row(_ key: String, _ value: String) -> some View {
        GridRow {
            Text(key).foregroundStyle(.secondary)
            Text(value)
        }
    }

    private func diagnose() {
        isWorking = true
        output = "正在诊断..."
        Task.detached {
            let result = ProcessInspector.diagnose()
            await MainActor.run {
                report = result
                output = "诊断完成。没有杀进程，也没有重载 plist。"
                isWorking = false
                notifier.success("诊断完成", detail: "维护状态已更新，没有执行危险操作。")
            }
        }
    }

    private func backupSessions() {
        isWorking = true
        output = "正在备份 sessions..."
        Task.detached {
            do {
                let backup = try ProcessInspector.backupSessions()
                let result = ProcessInspector.diagnose()
                await MainActor.run {
                    report = result
                    output = "Sessions 备份：\(backup?.path ?? "未找到 sessions 文件夹")。"
                    isWorking = false
                    if backup != nil {
                        notifier.success("备份成功", detail: "Sessions 已复制到备份目录。")
                    }
                }
            } catch {
                await MainActor.run {
                    output = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func resetSessions() {
        isWorking = true
        output = "正在移动 sessions..."
        Task.detached {
            do {
                let backup = try ProcessInspector.resetSessionsByMoving()
                let result = ProcessInspector.diagnose()
                await MainActor.run {
                    report = result
                    output = "Sessions 已移动到：\(backup?.path ?? "未找到 sessions 文件夹")。"
                    isWorking = false
                    if backup != nil {
                        notifier.success("移动成功", detail: "旧 Sessions 已移动到备份目录。")
                    }
                }
            } catch {
                await MainActor.run {
                    output = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }
}
