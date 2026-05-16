import SwiftUI
import AppKit

@MainActor
final class AppNotifier: ObservableObject {
    @Published var toast: ToastMessage?

    func success(_ title: String, detail: String) {
        toast = ToastMessage(title: title, detail: detail)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if self.toast?.title == title {
                self.toast = nil
            }
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
}

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "总览"
    case providerBridge = "Provider 配置"
    case recovery = "对话找回"
    case pluginSnapshot = "插件快照"
    case mobileReady = "扫码连接"
    case maintenance = "维护诊断"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: "gauge"
        case .providerBridge: "network"
        case .recovery: "clock.arrow.circlepath"
        case .pluginSnapshot: "shippingbox"
        case .mobileReady: "iphone.gen3"
        case .maintenance: "wrench.and.screwdriver"
        }
    }
}

struct ContentView: View {
    @State private var selection: AppSection = .dashboard
    @EnvironmentObject private var notifier: AppNotifier

    var body: some View {
        ZStack(alignment: .top) {
            NavigationSplitView {
                List(AppSection.allCases, selection: $selection) { section in
                    Label(section.rawValue, systemImage: section.icon)
                        .tag(section)
                }
                .navigationTitle("Codex++ Companion")
                .scrollContentBackground(.hidden)
                .background(Color.appSidebar)
                .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 230)
            } detail: {
                Group {
                    switch selection {
                    case .dashboard:
                        DashboardView()
                    case .providerBridge:
                        ProviderBridgeView()
                    case .recovery:
                        SessionRecoveryView()
                    case .pluginSnapshot:
                        PluginSnapshotView()
                    case .mobileReady:
                        MobileReadyView()
                    case .maintenance:
                        MaintenanceView()
                    }
                }
                .background(Color.appBackground)
            }
            if let toast = notifier.toast {
                SuccessToast(message: toast)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .background(WindowConfigurator())
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: notifier.toast)
        .preferredColorScheme(.dark)
    }
}

extension Color {
    static let appBackground = Color(red: 0.09, green: 0.10, blue: 0.11)
    static let appPanel = Color(red: 0.14, green: 0.15, blue: 0.16)
    static let appSidebar = Color(red: 0.11, green: 0.12, blue: 0.13)
    static let appBorder = Color.white.opacity(0.10)
}

struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(12)
        .background(Color.appPanel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appBorder)
        )
    }
}

struct InfoBlock: View {
    let title: String
    let text: String
    var icon: String = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CompactLinkButton: View {
    let title: String
    let systemImage: String
    let url: URL

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}

struct SuccessToast: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(.headline)
                Text(message.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.green.opacity(0.22), in: Capsule())
        .overlay(Capsule().stroke(.green.opacity(0.45)))
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.minSize = NSSize(width: 760, height: 520)
            window.isMovableByWindowBackground = true
            let current = window.frame
            if current.width > 1180 || current.height > 820 {
                let size = NSSize(width: 900, height: 620)
                if let screenFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
                    let origin = NSPoint(
                        x: screenFrame.midX - size.width / 2,
                        y: screenFrame.midY - size.height / 2
                    )
                    window.setFrame(NSRect(origin: origin, size: size), display: true, animate: true)
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
