import Foundation

struct MaintenanceReport {
    var appServerCount: Int = 0
    var orphanAppServerCount: Int = 0
    var sessionsSize: String = "0 bytes"
    var watcherExists: Bool = false
    var port9229Listening: Bool = false
    var notes: [String] = []
}

enum ProcessInspector {
    static func diagnose() -> MaintenanceReport {
        var report = MaintenanceReport()
        report.watcherExists = WatcherPlistManager.shared.exists()
        let sessionBytes = ConfigManager.shared.directorySize(ConfigManager.shared.sessionsURL)
        report.sessionsSize = ConfigManager.shared.formattedSize(sessionBytes)

        if let ps = try? ShellRunner.run("/bin/ps", arguments: ["-axo", "pid,ppid,comm,args"]) {
            let lines = ps.stdout.split(separator: "\n")
            let appServers = lines.filter { $0.contains("app-server") }
            report.appServerCount = appServers.count
            report.orphanAppServerCount = appServers.filter { line in
                let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                return parts.count > 1 && parts[1] == "1"
            }.count
        } else {
            report.notes.append("Unable to run ps.")
        }

        if let lsof = try? ShellRunner.run("/usr/sbin/lsof", arguments: ["-i", ":9229", "-sTCP:LISTEN"], timeout: 5) {
            report.port9229Listening = lsof.stdout.contains("LISTEN")
        }

        return report
    }

    static func cleanOrphanScript() -> String {
        """
        #!/bin/zsh
        # Review before running. This only targets app-server processes with PPID=1.
        ps -axo pid,ppid,comm,args | awk '/app-server/ && $2 == 1 { print $1 }'
        # To terminate after review:
        # ps -axo pid,ppid,comm,args | awk '/app-server/ && $2 == 1 { print $1 }' | xargs -r kill
        """
    }

    static func repairScript() -> String {
        """
        #!/bin/zsh
        # Review before running. This reloads the watcher plist if it exists.
        PLIST="$HOME/Library/LaunchAgents/com.bigpizzav3.codexplusplus.watcher.plist"
        if [[ -f "$PLIST" ]]; then
          launchctl unload "$PLIST"
          launchctl load "$PLIST"
        else
          echo "Watcher plist not found: $PLIST"
        fi
        """
    }

    static func backupSessions() throws -> URL? {
        let sessions = ConfigManager.shared.sessionsURL
        guard FileManager.default.fileExists(atPath: sessions.path) else { return nil }
        let backup = sessions.deletingLastPathComponent()
            .appendingPathComponent("sessions.bak.\(ConfigManager.timestamp())")
        try FileManager.default.copyItem(at: sessions, to: backup)
        return backup
    }

    static func resetSessionsByMoving() throws -> URL? {
        let sessions = ConfigManager.shared.sessionsURL
        guard FileManager.default.fileExists(atPath: sessions.path) else { return nil }
        let backup = sessions.deletingLastPathComponent()
            .appendingPathComponent("sessions.moved.\(ConfigManager.timestamp())")
        try FileManager.default.moveItem(at: sessions, to: backup)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        return backup
    }
}
