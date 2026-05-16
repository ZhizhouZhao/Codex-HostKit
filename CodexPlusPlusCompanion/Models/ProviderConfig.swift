import Foundation

struct ProviderConfig: Equatable {
    var apiKey: String = ""
    var baseURL: String = ""
    var providerName: String = "custom"
    var model: String = "openai/gpt-5.5-fast"

    var redactedKey: String {
        guard apiKey.count > 10 else { return apiKey.isEmpty ? "Missing" : "••••" }
        return "\(apiKey.prefix(6))…\(apiKey.suffix(4))"
    }
}
