import SwiftUI

struct MaintenanceView: View {
    @State private var report = MaintenanceReport()
    @State private var output = "点击“仅诊断”。"
    @State private var isWorking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "维护诊断", subtitle: "先做只读诊断。脚本只生成给用户确认，不自动执行。")
                Panel {
                    HStack {
                        Button("仅诊断") { diagnose() }.disabled(isWorking)
                        Button("生成清理孤儿进程脚本") { output = ProcessInspector.cleanOrphanScript() }
                        Button("生成修复脚本") { output = ProcessInspector.repairScript() }
                        Button("备份 Sessions") { backupSessions() }.disabled(isWorking)
                        Button("移动旧 Sessions 到备份") { resetSessions() }.disabled(isWorking)
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
            .padding(24)
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
