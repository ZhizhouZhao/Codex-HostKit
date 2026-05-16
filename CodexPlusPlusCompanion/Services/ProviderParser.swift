import Foundation

enum ProviderParser {
    static func parse(_ text: String) -> ProviderConfig {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var config = ProviderConfig()

        if let jsonConfig = parseJSON(trimmed) {
            config = jsonConfig
        }

        if config.apiKey.isEmpty, let bearer = firstMatch(in: trimmed, pattern: #"(?i)Authorization:\s*Bearer\s+([^\s'"\\]+)"#) {
            config.apiKey = bearer
        }

        if config.apiKey.isEmpty, let key = firstMatch(in: trimmed, pattern: #"(sk-[A-Za-z0-9_\-\.]+)"#) {
            config.apiKey = key
        }

        if config.baseURL.isEmpty {
            if let curlURL = firstMatch(in: trimmed, pattern: #"curl\s+(?:-[^\s]+\s+)*(?:'|")?(https?://[^'"\s]+)"#) {
                config.baseURL = baseFromEndpoint(curlURL)
            } else if let url = firstMatch(in: trimmed, pattern: #"(https?://[^\s'",}]+)"#) {
                config.baseURL = baseFromEndpoint(url)
            }
        }

        if let model = firstMatch(in: trimmed, pattern: #""model"\s*:\s*"([^"]+)""#), !model.isEmpty {
            config.model = model
        }

        config.baseURL = normalizeBaseURL(config.baseURL)
        config.providerName = inferProviderName(from: config.baseURL)
        return config
    }

    private static func parseJSON(_ text: String) -> ProviderConfig? {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        var config = ProviderConfig()
        config.apiKey = (object["api_key"] ?? object["apiKey"] ?? object["key"] ?? object["token"] ?? "") as? String ?? ""
        config.baseURL = (object["base_url"] ?? object["baseURL"] ?? object["url"] ?? object["endpoint"] ?? "") as? String ?? ""
        config.model = (object["model"] as? String) ?? config.model
        config.providerName = (object["provider"] as? String) ?? config.providerName
        return config
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func baseFromEndpoint(_ url: String) -> String {
        var value = url.trimmingCharacters(in: CharacterSet(charactersIn: "'\" "))
        for suffix in ["/responses", "/chat/completions", "/completions", "/models"] where value.hasSuffix(suffix) {
            value.removeLast(suffix.count)
        }
        return value
    }

    static func normalizeBaseURL(_ url: String) -> String {
        var value = url.trimmingCharacters(in: CharacterSet(charactersIn: "'\" \n\t/"))
        guard !value.isEmpty else { return "" }
        if !value.lowercased().hasPrefix("http://") && !value.lowercased().hasPrefix("https://") {
            value = "https://\(value)"
        }
        if !value.lowercased().hasSuffix("/v1") {
            value += "/v1"
        }
        return value
    }

    private static func inferProviderName(from baseURL: String) -> String {
        guard let host = URL(string: baseURL)?.host?.lowercased() else { return "custom" }
        if host.contains("kkrich") { return "kkrich" }
        return "custom"
    }
}
