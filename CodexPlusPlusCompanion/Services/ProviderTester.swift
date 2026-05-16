import Foundation

enum ProviderTester {
    static func testResponses(config: ProviderConfig) async -> String {
        guard let url = URL(string: config.baseURL + "/responses") else {
            return "Invalid base URL."
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": config.model,
            "input": "Reply only: ok",
            "stream": false,
            "max_output_tokens": 20
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(data: data, encoding: .utf8) ?? ""
            return "HTTP \(status)\n\(ShellRunner.sanitize(text, secrets: [config.apiKey]))"
        } catch {
            return "Request failed: \(error.localizedDescription)"
        }
    }
}
