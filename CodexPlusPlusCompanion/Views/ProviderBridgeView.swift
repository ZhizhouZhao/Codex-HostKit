import SwiftUI

struct ProviderBridgeView: View {
    @State private var pastedText = ""
    @State private var provider = ProviderConfig()
    @State private var log = "Paste provider info, then parse."
    @State private var isTesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Provider Bridge", subtitle: "Configure an OpenAI-compatible provider without editing TOML by hand.")
                Panel {
                    Text("Provider input").font(.headline)
                    TextEditor(text: $pastedText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .background(Color.black.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button("Parse Provider Info") { parse() }
                        Button("Save to Keychain") { saveKeychain() }.disabled(provider.apiKey.isEmpty)
                        Button("Apply Codex Config") { applyConfig() }.disabled(provider.baseURL.isEmpty)
                    }
                    HStack {
                        Button("Sync Env to launchctl") { syncLaunchctl() }.disabled(provider.apiKey.isEmpty)
                        Button("Sync Env to Codex++ Watcher") { syncWatcher() }.disabled(provider.apiKey.isEmpty)
                        Button("Test /v1/responses non-stream") { testProvider() }.disabled(provider.apiKey.isEmpty || provider.baseURL.isEmpty || isTesting)
                        Button("Test /v1/responses stream") { log = "Stream test is TODO in this MVP." }
                    }
                }
                Panel {
                    Text("Parsed result").font(.headline)
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                        row("Provider", provider.providerName)
                        row("Base URL", provider.baseURL.isEmpty ? "Missing" : provider.baseURL)
                        row("Model", provider.model)
                        row("API key", provider.redactedKey)
                    }
                }
                Panel {
                    Text("Output").font(.headline)
                    Text(log)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        GridRow {
            Text(key).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }

    private func parse() {
        provider = ProviderParser.parse(pastedText)
        log = "Parsed provider info. API key is \(provider.apiKey.isEmpty ? "missing" : "present"); base URL is \(provider.baseURL.isEmpty ? "missing" : provider.baseURL)."
    }

    private func saveKeychain() {
        do {
            try KeychainManager.saveAPIKey(provider.apiKey)
            log = "Saved API key to Keychain service \(KeychainManager.service)."
        } catch {
            log = error.localizedDescription
        }
    }

    private func applyConfig() {
        do {
            let backup = try ConfigManager.shared.writeProviderConfig(provider)
            log = "Wrote config.toml. Backup: \(backup?.path ?? "none, new file created")."
        } catch {
            log = error.localizedDescription
        }
    }

    private func syncLaunchctl() {
        do {
            try LaunchctlManager.setProviderEnvironment(apiKey: provider.apiKey)
            log = "Synced OPENAI_API_KEY and KKRICH_API_KEY to launchctl. Key value was not printed."
        } catch {
            log = error.localizedDescription
        }
    }

    private func syncWatcher() {
        do {
            guard WatcherPlistManager.shared.exists() else {
                log = "Watcher plist not found: \(WatcherPlistManager.shared.plistURL.path)"
                return
            }
            let backup = try WatcherPlistManager.shared.updateEnvironment(apiKey: provider.apiKey)
            log = "Updated watcher EnvironmentVariables. Backup: \(backup?.path ?? "none")."
        } catch {
            log = error.localizedDescription
        }
    }

    private func testProvider() {
        isTesting = true
        Task {
            let result = await ProviderTester.testResponses(config: provider)
            await MainActor.run {
                log = result
                isTesting = false
            }
        }
    }
}
