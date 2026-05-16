import AppKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                Panel {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("请作者喝杯咖啡").font(.headline)
                        Text("如果这个工具帮你省下了折腾时间，可以随手赞赏一下。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                        DonationCard(title: "微信", resourceName: "DonateWechat", tint: .green)
                        DonationCard(title: "支付宝", resourceName: "DonateAlipay", tint: .blue)
                    }
                }
            }
            .padding(16)
        }
    }

    private var header: some View {
        Panel {
            HStack(alignment: .top, spacing: 14) {
                HostKitLogoMark(size: 72)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Codex HostKit")
                        .font(.system(size: 28, weight: .bold))
                    Text("本机 provider、扫码连接、插件快照和对话找回工具。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("版本 \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack {
                    Spacer()
                    CompactLinkButton(
                        title: "作者的 GitHub",
                        systemImage: "person.crop.circle",
                        url: URL(string: "https://github.com/ZhizhouZhao")!
                    )
                }
            }
            .frame(minHeight: 82)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return [version, build].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " / ").isEmpty ? "本地构建" : [version, build].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " / ")
    }
}

private struct DonationCard: View {
    let title: String
    let resourceName: String
    let tint: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
            if let image = BundleImage.load(named: resourceName) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.12))
                    )
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(tint)
                    Text("等待添加 \(resourceName).jpeg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(Color.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.10))
                )
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint.opacity(0.28))
        )
    }
}

private enum BundleImage {
    static func load(named name: String) -> NSImage? {
        let extensions = ["jpeg", "jpg", "png"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }
}
