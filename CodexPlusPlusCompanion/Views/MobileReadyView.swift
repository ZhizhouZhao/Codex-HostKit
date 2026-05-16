import SwiftUI
import AppKit

struct MobileReadyView: View {
    @EnvironmentObject private var notifier: AppNotifier
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
            VStack(alignment: .leading, spacing: 12) {
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
                        Button("复制手机操作说明") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(instructions, forType: .string)
                            notifier.success("复制成功", detail: "手机连接说明已复制到剪贴板。")
                        }
                        .help("把手机端该怎么连接 Mac host 的步骤复制出来，方便发到手机或备忘录。")
                        Button("打开 ~/.codex 文件夹") { NSWorkspace.shared.open(ConfigManager.shared.codexDirectory) }
                            .help("~/.codex 是 Codex 在本机保存配置和历史的默认文件夹。")
                        Button("用默认编辑器打开 config.toml") { NSWorkspace.shared.open(ConfigManager.shared.configURL) }
                            .help("config.toml 是 Codex 的本地配置文件，里面记录模型和 provider 设置。")
                        Button("显示当前配置摘要") { showSummary() }
                            .help("只显示关键配置项，不显示 API key。")
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
            .padding(16)
        }
    }

    private func showSummary() {
        summary = ConfigManager.shared.summary()
            .map { "\($0.key): \($0.value.isEmpty ? "缺失" : $0.value)" }
            .sorted()
            .joined(separator: "\n")
        notifier.success("读取成功", detail: "已显示当前 Codex 配置摘要。")
    }
}
