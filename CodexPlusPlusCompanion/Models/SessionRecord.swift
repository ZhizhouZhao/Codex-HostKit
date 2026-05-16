import Foundation

struct SessionRecord: Identifiable, Hashable {
    let id: String
    let threadID: String
    let fileURL: URL
    let codexHome: URL
    let createdAt: Date?
    let modifiedAt: Date?
    let projectPath: String
    let model: String
    let provider: String
    let firstUserMessage: String
    let lastAssistantMessage: String
    let fileSize: UInt64
    let previewText: String

    var displayTitle: String {
        if !firstUserMessage.isEmpty { return firstUserMessage }
        return fileURL.lastPathComponent
    }
}
