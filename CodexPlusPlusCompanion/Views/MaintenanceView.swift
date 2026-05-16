import SwiftUI

struct MaintenanceView: View {
    @State private var report = MaintenanceReport()
    @State private var output = "Run Diagnose Only."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Maintenance", subtitle: "Read-only diagnostics first. Scripts are generated for review, not auto-executed.")
                Panel {
                    HStack {
                        Button("Diagnose Only") { diagnose() }
                        Button("Generate Clean Orphan Script") { output = ProcessInspector.cleanOrphanScript() }
                        Button("Generate Repair Script") { output = ProcessInspector.repairScript() }
                        Button("Backup Sessions") { backupSessions() }
                        Button("Reset Sessions by moving old folder to backup") { resetSessions() }
                    }
                }
                Panel {
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                        row("app-server processes", "\(report.appServerCount)")
                        row("orphan app-server PPID=1", "\(report.orphanAppServerCount)")
                        row("sessions size", report.sessionsSize)
                        row("watcher plist", report.watcherExists ? "exists" : "missing")
                        row("9229 listening", report.port9229Listening ? "yes" : "no")
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
        output = "Diagnosis complete. No processes were killed and no plist was reloaded."
    }

    private func backupSessions() {
        do {
            output = "Sessions backup: \((try ProcessInspector.backupSessions())?.path ?? "sessions folder not found")."
            diagnose()
        } catch {
            output = error.localizedDescription
        }
    }

    private func resetSessions() {
        do {
            output = "Sessions moved to: \((try ProcessInspector.resetSessionsByMoving())?.path ?? "sessions folder not found")."
            diagnose()
        } catch {
            output = error.localizedDescription
        }
    }
}
