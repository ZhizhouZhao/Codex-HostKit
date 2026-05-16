import Foundation
import AppKit

final class PluginSnapshotManager {
    nonisolated(unsafe) static let shared = PluginSnapshotManager()
    private let fileManager = FileManager.default

    var cacheURL: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex/plugins/cache", isDirectory: true)
    }

    var snapshotURL: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex/plugins/local-snapshot", isDirectory: true)
    }

    var marketplaceURL: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".agents/plugins/marketplace.json")
    }

    func cacheExists() -> Bool {
        fileManager.fileExists(atPath: cacheURL.path)
    }

    func marketplaceExists() -> Bool {
        fileManager.fileExists(atPath: marketplaceURL.path)
    }

    func scanInstalledPlugins() -> [PluginInfo] {
        scanPlugins(at: cacheURL)
    }

    func scanSnapshotPlugins() -> [PluginInfo] {
        scanPlugins(at: snapshotURL)
    }

    func backupPlugins() throws {
        guard cacheExists() else { return }
        if fileManager.fileExists(atPath: snapshotURL.path) {
            let archive = snapshotURL.deletingLastPathComponent()
                .appendingPathComponent("local-snapshot.bak.\(ConfigManager.timestamp())")
            try fileManager.moveItem(at: snapshotURL, to: archive)
        }
        try fileManager.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.copyItem(at: cacheURL, to: snapshotURL)
    }

    func restorePlugins() throws {
        guard fileManager.fileExists(atPath: snapshotURL.path) else { return }
        try fileManager.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: cacheURL.path) {
            let backup = cacheURL.deletingLastPathComponent()
                .appendingPathComponent("cache.bak.\(ConfigManager.timestamp())")
            try fileManager.moveItem(at: cacheURL, to: backup)
        }
        try fileManager.copyItem(at: snapshotURL, to: cacheURL)
    }

    func generateMarketplace() throws {
        let plugins = scanSnapshotPlugins()
        try fileManager.createDirectory(at: marketplaceURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: marketplaceURL.path) {
            let backup = marketplaceURL.deletingLastPathComponent()
                .appendingPathComponent("marketplace.json.bak.\(ConfigManager.timestamp())")
            try fileManager.copyItem(at: marketplaceURL, to: backup)
        }
        let entries = plugins.map { plugin in
            [
                "name": plugin.name,
                "source": "local-snapshot",
                "path": plugin.path.path,
                "hasManifest": plugin.hasManifest,
                "note": plugin.hasManifest ? "Local cached plugin snapshot." : "Manifest not found; manual check may be required."
            ] as [String: Any]
        }
        let json: [String: Any] = [
            "schemaVersion": 1,
            "generatedBy": "Codex++ Companion",
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "disclaimer": "Local snapshot only. This does not bypass account eligibility, OAuth authorization, paid access, server-side restrictions, or official plugin access controls.",
            "plugins": entries
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: marketplaceURL, options: .atomic)
    }

    func openPluginFolders() {
        NSWorkspace.shared.open(cacheURL.deletingLastPathComponent())
    }

    private func scanPlugins(at root: URL) -> [PluginInfo] {
        guard let children = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return []
        }
        return children.filter { ((try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false) }
            .map { url in
                let manifest = findManifest(under: url)
                return PluginInfo(
                    name: manifest.flatMap { manifestName($0) } ?? url.lastPathComponent,
                    path: url,
                    hasManifest: manifest != nil,
                    version: manifest.flatMap { manifestVersion($0) }
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func findManifest(under url: URL) -> URL? {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) else { return nil }
        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == "plugin.json" {
            return fileURL
        }
        return nil
    }

    private func manifestName(_ url: URL) -> String? {
        manifestField(url, field: "name")
    }

    private func manifestVersion(_ url: URL) -> String? {
        manifestField(url, field: "version")
    }

    private func manifestField(_ url: URL, field: String) -> String? {
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object[field] as? String
    }
}
