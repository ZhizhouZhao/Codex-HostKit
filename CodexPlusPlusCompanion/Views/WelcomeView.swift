import SwiftUI

struct WelcomeView: View {
    let showGuide: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                hero
                Panel {
                    Text("第一次使用建议按这个顺序来").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                        WelcomeStepCard(number: "1", title: "确认本机 Codex", text: "先确认 Mac 上的 Codex 能正常打开，并且可以进入扫码或本机会话。", icon: "checkmark.seal")
                        WelcomeStepCard(number: "2", title: "配置 Provider", text: "粘贴中转站 URL、API key、JSON 或 cURL，保存后写入本机 Codex 配置。", icon: "network")
                        WelcomeStepCard(number: "3", title: "手机扫码", text: "手机和 Mac 登录同一个 ChatGPT 账号，选择 Mac host / local thread。", icon: "qrcode")
                        WelcomeStepCard(number: "4", title: "看请求记录", text: "发送 Reply only ok，再去 provider dashboard 确认有请求记录。", icon: "chart.line.uptrend.xyaxis")
                    }
                }
                Panel {
                    Text("不要慌，这些页面各管一件事").font(.headline)
                    VStack(spacing: 10) {
                        GuideRow(icon: "network", title: "Provider 配置", text: "让本机 Codex 请求走你的 OpenAI-compatible provider。")
                        GuideRow(icon: "clock.arrow.circlepath", title: "对话找回", text: "扫描本机 sessions 和 history，找回看起来消失的旧 thread。")
                        GuideRow(icon: "shippingbox", title: "插件快照", text: "备份已经安装过的插件缓存，网络变化后更容易恢复入口。")
                        GuideRow(icon: "iphone.gen3", title: "扫码连接", text: "解释手机 Codex Mobile 如何控制 Mac host，而不是走 Cloud thread。")
                        GuideRow(icon: "wrench.and.screwdriver", title: "维护诊断", text: "只读检查 app-server、watcher、sessions 和端口状态。")
                    }
                }
            }
            .padding(16)
        }
    }

    private var hero: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Codex HostKit 快速开始")
                    .font(.system(size: 28, weight: .bold))
                Text("把本机 provider、手机扫码、插件快照、对话找回这些容易混在一起的事情分开处理。按步骤完成后，你就能更明确地判断请求到底走哪里、问题卡在哪。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    FeaturePill(title: "本机配置", icon: "macbook")
                    FeaturePill(title: "手机连接", icon: "iphone.gen3")
                    FeaturePill(title: "插件备份", icon: "shippingbox")
                }
                Button("打开欢迎教程") { showGuide() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}
struct WelcomeOnboardingView: View {
    let close: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(
            eyebrow: "先认识它",
            title: "Codex HostKit",
            text: "手机继续用 ChatGPT 登录连接 Mac，本机真实模型请求走你配置的 provider。这个工具帮你少碰终端、少猜状态。"
        ),
        OnboardingPage(
            eyebrow: "第一步",
            title: "配置 Provider",
            text: "到 Provider 配置页粘贴 API key、URL、JSON 或 cURL。保存 Keychain，应用 config，再按需同步 launchctl 和 watcher。"
        ),
        OnboardingPage(
            eyebrow: "第二步",
            title: "扫码连接 Mac",
            text: "手机和 Mac 登录同一个 ChatGPT 账号，扫描 Mac 上的二维码，选择 Mac host / local thread，不要选 Cloud thread。"
        ),
        OnboardingPage(
            eyebrow: "遇到不对劲",
            title: "先看找回和诊断",
            text: "旧对话看不见就去对话找回；插件不见就去插件快照；卡住时先跑维护诊断，它不会杀进程。"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appBackground)
                VStack(spacing: 18) {
                    Text(pages[page].eyebrow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(pages[page].title)
                        .font(.system(size: 36, weight: .bold))
                    Text(pages[page].text)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 430)
                    HStack(spacing: 6) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? Color.green : Color.white.opacity(0.18))
                                .frame(width: index == page ? 20 : 7, height: 7)
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(34)
            }
            Divider().opacity(0.3)
            HStack {
                Button(page == 0 ? "跳过" : "上一步") {
                    if page == 0 {
                        close()
                    } else {
                        page -= 1
                    }
                }
                Spacer()
                Button(page == pages.count - 1 ? "开始使用" : "下一步") {
                    if page == pages.count - 1 {
                        close()
                    } else {
                        page += 1
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .background(Color.appPanel)
    }
}

private struct OnboardingPage {
    let eyebrow: String
    let title: String
    let text: String
}

private struct WelcomeStepCard: View {
    let number: String
    let title: String
    let text: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Color.green.opacity(0.18))
                Text(number).font(.headline).foregroundStyle(.green)
            }
            .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 5) {
                Label(title, systemImage: icon)
                    .font(.headline)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct GuideRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(text).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
        }
        Divider().opacity(0.22)
    }
}
