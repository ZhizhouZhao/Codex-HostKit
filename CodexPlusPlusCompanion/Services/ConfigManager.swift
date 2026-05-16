import Foundation

final class ConfigManager {
    nonisolated(unsafe) static let shared = ConfigManager()
    private let fileManager = FileManager.default

    var codexDirectory: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
    }

    var configURL: URL {
        codexDirectory.appendingPathComponent("config.toml")
    }

    var sessionsURL: URL {
        codexDirectory.appendingPathComponent("sessions", isDirectory: true)
    }

    func configExists() -> Bool {
        fileManager.fileExists(atPath: configURL.path)
    }

    func readConfig() -> String {
        (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
    }

    func backupConfig() throws -> URL? {
        guard configExists() else { return nil }
        let backupURL = configURL.deletingLastPathComponent()
            .appendingPathComponent("config.toml.bak.\(Self.timestamp())")
        try fileManager.copyItem(at: configURL, to: backupURL)
        return backupURL
    }

    func writeProviderConfig(_ provider: ProviderConfig) throws -> URL? {
        try fileManager.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        let backup = try backupConfig()
        let toml = """
        model = "\(provider.model)"
        model_provider = "custom"

        model_reasoning_effort = "low"
        model_reasoning_summary = "none"
        model_verbosity = "low"

        network_access = "enabled"
        disable_response_storage = true

        request_max_retries = 3
        stream_max_retries = 10
        stream_idle_timeout_ms = 600000

        [model_providers.custom]
        name = "Custom Provider"
        base_url = "\(provider.baseURL)"
        env_key = "OPENAI_API_KEY"
        wire_api = "responses"
        supports_websockets = false

        """
        try toml.write(to: configURL, atomically: true, encoding: .utf8)
        return backup
    }

    func summary() -> [String: String] {
        let content = readConfig()
        return [
            "model": value(for: "model", in: content),
            "model_provider": value(for: "model_provider", in: content),
            "base_url": value(for: "base_url", in: content),
            "env_key": value(for: "env_key", in: content),
            "wire_api": value(for: "wire_api", in: content)
        ]
    }

    func directorySize(_ url: URL) -> UInt64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var size: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            size += UInt64(values?.fileSize ?? 0)
        }
        return size
    }

    func formattedSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func value(for key: String, in toml: String) -> String {
        let pattern = #"(?m)^\#(key)\s*=\s*"([^"]*)""#.replacingOccurrences(of: "#(key)", with: NSRegularExpression.escapedPattern(for: key))
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: toml, range: NSRange(toml.startIndex..<toml.endIndex, in: toml)),
              let range = Range(match.range(at: 1), in: toml) else {
            return ""
        }
        return String(toml[range])
    }

    static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
