import SwiftUI

struct PluginSnapshotView: View {
    @State private var plugins: [PluginInfo] = []
    @State private var log = "Scan installed plugins to begin."

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: "Local Plugin Snapshot", subtitle: "Back up and restore plugins already present on this Mac.")
            Panel {
                HStack {
                    Button("Scan Installed Plugins") { scan() }
                    Button("Backup Plugins") { backup() }
                    Button("Restore Plugins") { restore() }
                    Button("Generate Local Marketplace") { marketplace() }
                    Button("Open Plugin Folders") { PluginSnapshotManager.shared.openPluginFolders() }
                }
                Text("OAuth plugins may require reauthorization. Computer Use may still need Screen Recording and Accessibility permissions.")
                    .foregroundStyle(.secondary)
            }
            Panel {
                Table(plugins) {
                    TableColumn("Name") { Text($0.name) }
                    TableColumn("Manifest") { Text($0.hasManifest ? "Found" : "Needs check") }
                    TableColumn("Version") { Text($0.version ?? "-") }
                    TableColumn("Path") { Text($0.path.path).textSelection(.enabled) }
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
        log = "Found \(plugins.count) installed plugin cache folder(s)."
    }

    private func backup() {
        do {
            try PluginSnapshotManager.shared.backupPlugins()
            log = "Backed up plugin cache to \(PluginSnapshotManager.shared.snapshotURL.path)."
        } catch {
            log = error.localizedDescription
        }
    }

    private func restore() {
        do {
            try PluginSnapshotManager.shared.restorePlugins()
            log = "Restored local snapshot to plugin cache. Existing cache was moved to a timestamped backup if present."
            scan()
        } catch {
            log = error.localizedDescription
        }
    }

    private func marketplace() {
        do {
            try PluginSnapshotManager.shared.generateMarketplace()
            log = "Generated \(PluginSnapshotManager.shared.marketplaceURL.path)."
        } catch {
            log = error.localizedDescription
        }
    }
}
