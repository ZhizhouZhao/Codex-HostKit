import SwiftUI
import AppKit

struct MobileReadyView: View {
    @State private var summary = ""

    private let instructions = """
    1. Fully close ChatGPT App on phone.
    2. Reopen ChatGPT.
    3. Go to Codex.
    4. Choose Mac host / local thread.
    5. Do not choose Cloud.
    6. Create a new thread.
    7. Send: Reply only ok.
    8. Check provider dashboard for request record.
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Mobile Ready", subtitle: "Make sure Codex Mobile is controlling this Mac host, not a Cloud thread.")
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ChatGPT account login is still needed on phone.")
                        Text("Phone must choose Mac host / local thread.")
                        Text("Do not use Cloud thread.")
                        Text("Local provider billing only works when mobile connects to Mac host.")
                        Text("Provider request evidence should be checked in the provider dashboard.")
                    }
                }
                Panel {
                    HStack {
                        Button("Copy Mobile Instructions") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(instructions, forType: .string) }
                        Button("Open ~/.codex folder") { NSWorkspace.shared.open(ConfigManager.shared.codexDirectory) }
                        Button("Open config.toml in default editor") { NSWorkspace.shared.open(ConfigManager.shared.configURL) }
                        Button("Show current config summary") { showSummary() }
                    }
                }
                Panel {
                    Text(instructions).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                }
                if !summary.isEmpty {
                    Panel {
                        Text(summary).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                    }
                }
            }
            .padding(24)
        }
    }

    private func showSummary() {
        summary = ConfigManager.shared.summary()
            .map { "\($0.key): \($0.value.isEmpty ? "missing" : $0.value)" }
            .sorted()
            .joined(separator: "\n")
    }
}
