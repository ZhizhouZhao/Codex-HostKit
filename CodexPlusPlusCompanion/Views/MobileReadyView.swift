import SwiftUI
import AppKit

struct MobileReadyView: View {
    @EnvironmentObject private var notifier: AppNotifier
    @State private var summary = ""

    private let instructions = """
    1. Mac 上打开 Codex / Codex++ 的 Codex Mobile 页面。
    2. 手机 ChatGPT 登录同一个账号。
    3. 手机进入 Codex Mobile，扫描 Mac 上的二维码。
    4. 手机选择 Mac host / local thread。
    5. 不要选择 Cloud thread。
    6. 创建一个新 thread，发送：Reply only ok。
    7. 回到 provider dashboard 检查是否出现请求记录。
    8. 如果 provider 有记录，说明手机控制 Mac，但模型请求走的是本机 provider 配置。
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                PageHeader(title: "扫码连接", subtitle: "手机用 ChatGPT 登录建立连接，Mac 本地用 provider 配置控制计费。")
                Panel {
                    InfoBlock(
                        title: "这不是免登录，也不是替代 Codex++",
                        text: "Codex Mobile 要远程连接 Mac host，手机 ChatGPT 和 Mac GUI 仍需要登录同一个 ChatGPT 账号。这个 App 解决的是：保留扫码连接能力，但让 Mac 本地真实模型请求走你配置的中转站或 OpenAI-compatible API。",
                        icon: "qrcode"
                    )
                    Divider().opacity(0.25)
                    InfoBlock(
                        title: "计费判断方法",
                        text: "手机发消息后，如果你选择的是 Mac host / local thread，并且 provider dashboard 出现请求记录，就说明手机只是控制 Mac，实际消耗走本机 provider。选择 Cloud thread 时不会走本机 provider 配置。",
                        icon: "creditcard"
                    )
                    Divider().opacity(0.25)
                    InfoBlock(
                        title: "为什么会导致对话看起来丢失",
                        text: "频繁切换账号登录、provider、watcher 或 app-server 后，本地 thread 列表可能不完整。遇到这种情况请去“对话找回”，它会扫描 Mac 本地 sessions，不修改远端 ChatGPT Cloud 历史。",
                        icon: "clock.arrow.circlepath"
                    )
                }
                Panel {
                    Text("扫码连接步骤").font(.headline)
                    Text(instructions)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                Panel {
                    Text("常用操作").font(.headline)
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            actionButtons
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            actionButtons
                        }
                    }
                }
                if !summary.isEmpty {
                    Panel {
                        Text("当前 Codex 配置摘要").font(.headline)
                        Text(summary).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                    }
                }
            }
            .padding(16)
        }
    }

    private var actionButtons: some View {
        Group {
                        Button("复制手机操作说明") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(instructions, forType: .string)
                            notifier.success("复制成功", detail: "手机连接说明已复制到剪贴板。")
                        }
                        .help("把手机端该怎么连接 Mac host 的步骤复制出来，方便发到手机或备忘录。")
            CompactLinkButton(
                title: "打开 Codex++ GitHub",
                systemImage: "arrow.up.right.square",
                url: URL(string: "https://github.com/bigpizzav3/codex-plus-plus")!
            )
            .help("如果需要 Codex++ 的插件入口、商店入口或扫码连接增强，可以从 GitHub 获取 Codex++。")
                        Button("打开 ~/.codex 文件夹") { NSWorkspace.shared.open(ConfigManager.shared.codexDirectory) }
                            .help("~/.codex 是 Codex 在本机保存配置和历史的默认文件夹。")
                        Button("用默认编辑器打开 config.toml") { NSWorkspace.shared.open(ConfigManager.shared.configURL) }
                            .help("config.toml 是 Codex 的本地配置文件，里面记录模型和 provider 设置。")
                        Button("显示当前配置摘要") { showSummary() }
                            .help("只显示关键配置项，不显示 API key。")
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
