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
            "generatedBy": "Codex HostKit",
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
        findPluginManifests(under: root)
            .map { manifest in
                let pluginRoot = manifest.deletingLastPathComponent().deletingLastPathComponent()
                let manifestObject = readManifest(manifest)
                let interface = manifestObject?["interface"] as? [String: Any]
                let icon = preferredIconURL(from: interface, manifestURL: manifest)
                let name = manifestObject?["name"] as? String
                let displayName = interface?["displayName"] as? String

                return PluginInfo(
                    name: name ?? pluginRoot.lastPathComponent,
                    displayName: displayName ?? name ?? pluginRoot.lastPathComponent,
                    path: pluginRoot,
                    hasManifest: true,
                    version: manifestObject?["version"] as? String,
                    iconURL: icon,
                    brandColor: interface?["brandColor"] as? String,
                    category: interface?["category"] as? String
                )
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private func findPluginManifests(under root: URL) -> [URL] {
        guard let sources = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return []
        }

        var manifests: [URL] = []
        for source in sources where isDirectory(source) {
            guard let pluginNames = try? fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: [.isDirectoryKey]) else {
                continue
            }
            for pluginName in pluginNames where isDirectory(pluginName) {
                guard let versions = try? fileManager.contentsOfDirectory(at: pluginName, includingPropertiesForKeys: [.isDirectoryKey]) else {
                    continue
                }
                for version in versions where isDirectory(version) {
                    let manifest = version.appendingPathComponent(".codex-plugin/plugin.json")
                    if fileManager.fileExists(atPath: manifest.path) {
                        manifests.append(manifest)
                    }
                }
            }
        }
        return manifests
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    private func readManifest(_ url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object
    }

    private func resolveManifestAsset(_ value: String, manifestURL: URL) -> URL? {
        guard !value.hasPrefix("http://"), !value.hasPrefix("https://") else {
            return nil
        }
        let pluginRoot = manifestURL.deletingLastPathComponent().deletingLastPathComponent()
        let cleaned = value.hasPrefix("./") ? String(value.dropFirst(2)) : value
        let url = pluginRoot.appendingPathComponent(cleaned)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func preferredIconURL(from interface: [String: Any]?, manifestURL: URL) -> URL? {
        let candidates = [
            interface?["composerIcon"] as? String,
            interface?["logo"] as? String
        ].compactMap { $0 }
            .compactMap { resolveManifestAsset($0, manifestURL: manifestURL) }

        return candidates.first { ["png", "jpg", "jpeg", "icns"].contains($0.pathExtension.lowercased()) }
            ?? candidates.first
    }
}
