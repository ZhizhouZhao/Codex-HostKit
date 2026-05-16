import Foundation

final class WatcherPlistManager {
    nonisolated(unsafe) static let shared = WatcherPlistManager()
    private let fileManager = FileManager.default

    var plistURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.bigpizzav3.codexplusplus.watcher.plist")
    }

    func exists() -> Bool {
        fileManager.fileExists(atPath: plistURL.path)
    }

    func hasEnvironmentVariables() -> Bool {
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return false
        }
        return plist["EnvironmentVariables"] is [String: Any]
    }

    func backup() throws -> URL? {
        guard exists() else { return nil }
        let backupURL = plistURL.deletingLastPathComponent()
            .appendingPathComponent("com.bigpizzav3.codexplusplus.watcher.plist.bak.\(ConfigManager.timestamp())")
        try fileManager.copyItem(at: plistURL, to: backupURL)
        return backupURL
    }

    func updateEnvironment(apiKey: String) throws -> URL? {
        guard exists() else { return nil }
        let backupURL = try backup()
        let data = try Data(contentsOf: plistURL)
        var plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] ?? [:]
        var env = plist["EnvironmentVariables"] as? [String: String] ?? [:]
        env["OPENAI_API_KEY"] = apiKey
        env["KKRICH_API_KEY"] = apiKey
        plist["EnvironmentVariables"] = env
        let output = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try output.write(to: plistURL, options: Data.WritingOptions.atomic)
        return backupURL
    }
}
