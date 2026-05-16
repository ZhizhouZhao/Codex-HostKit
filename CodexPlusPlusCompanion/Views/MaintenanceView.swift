import SwiftUI

struct MaintenanceView: View {
    @State private var report = MaintenanceReport()
    @State private var output = "点击“仅诊断”。"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "维护诊断", subtitle: "先做只读诊断。脚本只生成给用户确认，不自动执行。")
                Panel {
                    HStack {
                        Button("仅诊断") { diagnose() }
                        Button("生成清理孤儿进程脚本") { output = ProcessInspector.cleanOrphanScript() }
                        Button("生成修复脚本") { output = ProcessInspector.repairScript() }
                        Button("备份 Sessions") { backupSessions() }
                        Button("移动旧 Sessions 到备份") { resetSessions() }
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
        report = ProcessInspector.diagnose()
        output = "诊断完成。没有杀进程，也没有重载 plist。"
    }

    private func backupSessions() {
        do {
            output = "Sessions 备份：\((try ProcessInspector.backupSessions())?.path ?? "未找到 sessions 文件夹")。"
            diagnose()
        } catch {
            output = error.localizedDescription
        }
    }

    private func resetSessions() {
        do {
            output = "Sessions 已移动到：\((try ProcessInspector.resetSessionsByMoving())?.path ?? "未找到 sessions 文件夹")。"
            diagnose()
        } catch {
            output = error.localizedDescription
        }
    }
}
