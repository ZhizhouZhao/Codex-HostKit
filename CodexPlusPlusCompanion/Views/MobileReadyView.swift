import SwiftUI
import AppKit

struct MobileReadyView: View {
    @State private var summary = ""

    private let instructions = """
    1. 在手机上完全关闭 ChatGPT App。
    2. 重新打开 ChatGPT。
    3. 进入 Codex。
    4. 选择 Mac host / local thread。
    5. 不要选择 Cloud。
    6. 创建一个新 thread。
    7. 发送：Reply only ok。
    8. 到 provider dashboard 检查是否有请求记录。
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "手机连接", subtitle: "确认 Codex Mobile 连接的是这台 Mac host，而不是 Cloud thread。")
                Panel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("手机端仍然需要 ChatGPT 账号登录。")
                        Text("手机必须选择 Mac host / local thread。")
                        Text("不要使用 Cloud thread。")
                        Text("只有连接 Mac host 时，本地 provider 计费才会生效。")
                        Text("请到 provider dashboard 检查请求记录。")
                    }
                }
                Panel {
                    HStack {
                        Button("复制手机操作说明") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(instructions, forType: .string) }
                        Button("打开 ~/.codex 文件夹") { NSWorkspace.shared.open(ConfigManager.shared.codexDirectory) }
                        Button("用默认编辑器打开 config.toml") { NSWorkspace.shared.open(ConfigManager.shared.configURL) }
                        Button("显示当前配置摘要") { showSummary() }
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
            .map { "\($0.key): \($0.value.isEmpty ? "缺失" : $0.value)" }
            .sorted()
            .joined(separator: "\n")
    }
}
