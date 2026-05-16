import Foundation

struct ShellResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

enum ShellRunner {
    static func run(_ executable: String, arguments: [String], timeout: TimeInterval = 10, secrets: [String] = []) throws -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if process.isRunning {
            process.terminate()
        }
        process.waitUntilExit()

        let stdout = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ShellResult(
            exitCode: process.terminationStatus,
            stdout: sanitize(stdout, secrets: secrets),
            stderr: sanitize(stderr, secrets: secrets)
        )
    }

    static func sanitize(_ text: String, secrets: [String]) -> String {
        var sanitized = text
        for secret in secrets where !secret.isEmpty {
            sanitized = sanitized.replacingOccurrences(of: secret, with: "••••REDACTED••••")
        }
        sanitized = sanitized.replacingOccurrences(
            of: #"sk-[A-Za-z0-9_\-]{8,}"#,
            with: "sk-••••REDACTED••••",
            options: .regularExpression
        )
        return sanitized
    }
}
