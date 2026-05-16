import Foundation
import AppKit

final class SessionRecoveryManager {
    nonisolated(unsafe) static let shared = SessionRecoveryManager()
    private let fileManager = FileManager.default
    private let previewReadLimit = 1_000_000

    func scan() -> [SessionRecord] {
        scanRoots().flatMap(scanRoot).sorted {
            ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast)
        }
    }

    func scanRoots() -> [URL] {
        var roots = [fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)]
        if let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"], !codexHome.isEmpty {
            let url = URL(fileURLWithPath: NSString(string: codexHome).expandingTildeInPath, isDirectory: true)
            if !roots.contains(url) { roots.append(url) }
        }
        return roots
    }

    func exportMarkdown(_ session: SessionRecord) throws -> URL {
        let directory = exportDirectory()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(safeFileName(session.id)).md")
        let fullContent = try redactedContent(for: session)
        let markdown = """
        # Codex Session Export

        - Session ID: \(session.id)
        - Thread ID: \(session.threadID.isEmpty ? "未找到" : session.threadID)
        - Project: \(session.projectPath.isEmpty ? "未知" : session.projectPath)
        - Model: \(session.model.isEmpty ? "未知" : session.model)
        - Provider: \(session.provider.isEmpty ? "未知" : session.provider)
        - File: \(session.fileURL.path)

        > 注意：导出内容可能包含代码、路径、命令输出和项目隐私。API key 和常见 token 已做基础脱敏。

        ```text
        \(fullContent)
        ```
        """
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func exportJSON(_ session: SessionRecord) throws -> URL {
        let directory = exportDirectory()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(safeFileName(session.id)).json")
        let object: [String: Any] = [
            "session_id": session.id,
            "thread_id": session.threadID,
            "project_path": session.projectPath,
            "model": session.model,
            "provider": session.provider,
            "file_path": session.fileURL.path,
            "created_at": session.createdAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
            "modified_at": session.modifiedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
            "file_size": session.fileSize,
            "redacted_content": try redactedContent(for: session),
            "warning": "导出内容可能包含代码、路径、命令输出和项目隐私。API key 和常见 token 已做基础脱敏。"
        ]
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: Data.WritingOptions.atomic)
        return url
    }

    func backupAllSessions() throws -> [URL] {
        try scanRoots().compactMap { root in
            let sessions = root.appendingPathComponent("sessions", isDirectory: true)
            guard fileManager.fileExists(atPath: sessions.path) else { return nil }
            let backup = root.appendingPathComponent("sessions.backup.\(ConfigManager.timestamp())", isDirectory: true)
            try fileManager.copyItem(at: sessions, to: backup)
            return backup
        }
    }

    func moveOldOrLargeSessionsToBackup(days: Int = 30, largeFileBytes: UInt64 = 25 * 1024 * 1024) throws -> URL {
        let backupRoot = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/session-rescue-backup/\(ConfigManager.timestamp())", isDirectory: true)
        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)

        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        var moved = 0
        for record in scan() {
            let isOld = (record.modifiedAt ?? .distantFuture) < cutoff
            let isLarge = record.fileSize >= largeFileBytes
            guard isOld || isLarge else { continue }
            let destination = backupRoot.appendingPathComponent(record.fileURL.lastPathComponent)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.moveItem(at: record.fileURL, to: backupRoot.appendingPathComponent("\(UUID().uuidString)-\(record.fileURL.lastPathComponent)"))
            } else {
                try fileManager.moveItem(at: record.fileURL, to: destination)
            }
            moved += 1
        }

        let note = backupRoot.appendingPathComponent("README.txt")
        try "Moved \(moved) session file(s). Criteria: older than \(days) days or larger than \(ByteCountFormatter.string(fromByteCount: Int64(largeFileBytes), countStyle: .file)). Original files were moved, not deleted.\n".write(to: note, atomically: true, encoding: .utf8)
        return backupRoot
    }

    func openInFinder(_ session: SessionRecord) {
        NSWorkspace.shared.activateFileViewerSelecting([session.fileURL])
    }

    private func scanRoot(_ root: URL) -> [SessionRecord] {
        var records: [SessionRecord] = []
        let sessions = root.appendingPathComponent("sessions", isDirectory: true)
        let history = root.appendingPathComponent("history.jsonl")

        if let enumerator = fileManager.enumerator(at: sessions, includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey, .fileSizeKey, .isRegularFileKey]) {
            for case let fileURL as URL in enumerator {
                guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
                records.append(parseSessionFile(fileURL, codexHome: root))
            }
        }

        if fileManager.fileExists(atPath: history.path) {
            records.append(parseSessionFile(history, codexHome: root))
        }

        return records
    }

    private func parseSessionFile(_ fileURL: URL, codexHome: URL) -> SessionRecord {
        let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey, .fileSizeKey])
        let preview = readPreview(fileURL)
        let raw = preview.text
        let redacted = redact(raw)
        let jsonObjects = parseJSONObjects(raw)
        let sessionID = firstString(in: jsonObjects, keys: ["session_id", "sessionId", "id", "conversation_id"]) ?? fileURL.deletingPathExtension().lastPathComponent
        let threadID = firstString(in: jsonObjects, keys: ["thread_id", "threadId", "thread"]) ?? ""
        let project = firstString(in: jsonObjects, keys: ["cwd", "project_path", "projectPath", "workspace", "workdir"]) ?? ""
        let model = firstString(in: jsonObjects, keys: ["model", "model_name", "modelName"]) ?? ""
        let provider = inferProvider(from: firstString(in: jsonObjects, keys: ["provider", "model_provider", "modelProvider"]) ?? "", model: model, raw: raw)
        let userMessages = stringsNearRoles(in: jsonObjects, role: "user")
        let assistantMessages = stringsNearRoles(in: jsonObjects, role: "assistant")

        return SessionRecord(
            id: sessionID,
            threadID: threadID,
            fileURL: fileURL,
            codexHome: codexHome,
            createdAt: values?.creationDate,
            modifiedAt: values?.contentModificationDate,
            projectPath: project,
            model: model,
            provider: provider,
            firstUserMessage: summarize(userMessages.first ?? firstLikelyMessage(raw) ?? ""),
            lastAssistantMessage: summarize(assistantMessages.last ?? ""),
            fileSize: UInt64(values?.fileSize ?? 0),
            previewText: preview.truncated ? redacted + "\n\n[预览已截断：列表扫描只读取文件前 1 MB，导出会读取完整文件。]" : redacted,
            previewTruncated: preview.truncated
        )
    }

    private func readPreview(_ fileURL: URL) -> (text: String, truncated: Bool) {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            return ("", false)
        }
        defer { try? handle.close() }
        let data = handle.readData(ofLength: previewReadLimit + 1)
        let truncated = data.count > previewReadLimit
        let clipped = truncated ? data.prefix(previewReadLimit) : data[...]
        return (String(data: Data(clipped), encoding: .utf8) ?? "", truncated)
    }

    private func redactedContent(for session: SessionRecord) throws -> String {
        let raw = try String(contentsOf: session.fileURL, encoding: .utf8)
        return redact(raw)
    }

    private func parseJSONObjects(_ raw: String) -> [Any] {
        var objects: [Any] = []
        if let data = raw.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) {
            objects.append(object)
        }
        for line in raw.split(separator: "\n") {
            guard let data = line.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) else { continue }
            objects.append(object)
        }
        return objects
    }

    private func firstString(in objects: [Any], keys: [String]) -> String? {
        for object in objects {
            if let value = findString(in: object, keys: keys), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func findString(in object: Any, keys: [String]) -> String? {
        if let dictionary = object as? [String: Any] {
            for key in keys {
                if let value = dictionary[key] as? String { return value }
                if let value = dictionary[key] { return String(describing: value) }
            }
            for value in dictionary.values {
                if let found = findString(in: value, keys: keys) { return found }
            }
        } else if let array = object as? [Any] {
            for value in array {
                if let found = findString(in: value, keys: keys) { return found }
            }
        }
        return nil
    }

    private func stringsNearRoles(in objects: [Any], role: String) -> [String] {
        var messages: [String] = []
        for object in objects {
            collectRoleMessages(object, role: role, into: &messages)
        }
        return messages
    }

    private func collectRoleMessages(_ object: Any, role: String, into messages: inout [String]) {
        if let dictionary = object as? [String: Any] {
            let foundRole = (dictionary["role"] as? String) ?? (dictionary["author"] as? String) ?? ""
            if foundRole.localizedCaseInsensitiveContains(role),
               let content = firstContentString(in: dictionary) {
                messages.append(content)
            }
            for value in dictionary.values {
                collectRoleMessages(value, role: role, into: &messages)
            }
        } else if let array = object as? [Any] {
            for value in array {
                collectRoleMessages(value, role: role, into: &messages)
            }
        }
    }

    private func firstContentString(in dictionary: [String: Any]) -> String? {
        for key in ["content", "text", "message", "input", "output"] {
            if let value = dictionary[key] as? String { return value }
            if let value = dictionary[key] as? [String: Any],
               let nested = firstContentString(in: value) { return nested }
            if let array = dictionary[key] as? [Any] {
                let joined = array.compactMap { item -> String? in
                    if let string = item as? String { return string }
                    if let dict = item as? [String: Any] { return firstContentString(in: dict) }
                    return nil
                }.joined(separator: "\n")
                if !joined.isEmpty { return joined }
            }
        }
        return nil
    }

    private func firstLikelyMessage(_ raw: String) -> String? {
        raw.split(separator: "\n").first { $0.localizedCaseInsensitiveContains("user") }.map(String.init)
    }

    private func inferProvider(from provider: String, model: String, raw: String) -> String {
        let combined = "\(provider) \(model) \(raw.prefix(2000))".lowercased()
        if combined.contains("kkrich") { return "KKRICH" }
        if combined.contains("custom") { return "custom" }
        if combined.contains("openai") { return "OpenAI" }
        return provider.isEmpty ? "未知" : provider
    }

    func redact(_ text: String) -> String {
        var output = ShellRunner.sanitize(text, secrets: [])
        let replacements = [
            #"(?i)Bearer\s+[A-Za-z0-9_\-\.=]{8,}"#: "Bearer ••••REDACTED••••",
            #"(?i)(OPENAI_API_KEY|KKRICH_API_KEY|ANTHROPIC_API_KEY|API_KEY)\s*[:=]\s*["']?[^"',\s}]{8,}"#: "$1=••••REDACTED••••",
            #"(?i)("?(OPENAI_API_KEY|KKRICH_API_KEY|API_KEY)"?\s*:\s*")([^"]+)(")"#: "$1••••REDACTED••••$4"
        ]
        for (pattern, replacement) in replacements {
            output = output.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return output
    }

    private func summarize(_ text: String) -> String {
        let flat = redact(text).replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard flat.count > 160 else { return flat }
        return String(flat.prefix(160)) + "..."
    }

    private func exportDirectory() -> URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/CodexSessionExports", isDirectory: true)
    }

    private func safeFileName(_ value: String) -> String {
        value.replacingOccurrences(of: #"[^A-Za-z0-9_\-\.]+"#, with: "-", options: .regularExpression)
    }
}
