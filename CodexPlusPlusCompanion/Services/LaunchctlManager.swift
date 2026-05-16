import Foundation

enum LaunchctlManager {
    static func getenv(_ name: String) -> String? {
        guard let result = try? ShellRunner.run("/bin/launchctl", arguments: ["getenv", name]) else { return nil }
        let value = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    static func setProviderEnvironment(apiKey: String) throws {
        _ = try ShellRunner.run("/bin/launchctl", arguments: ["setenv", "OPENAI_API_KEY", apiKey], secrets: [apiKey])
        _ = try ShellRunner.run("/bin/launchctl", arguments: ["setenv", "KKRICH_API_KEY", apiKey], secrets: [apiKey])
    }
}
