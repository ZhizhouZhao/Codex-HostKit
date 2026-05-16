import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case providerBridge = "Provider Bridge"
    case pluginSnapshot = "Local Plugin Snapshot"
    case mobileReady = "Mobile Ready"
    case maintenance = "Maintenance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: "gauge"
        case .providerBridge: "network"
        case .pluginSnapshot: "shippingbox"
        case .mobileReady: "iphone.gen3"
        case .maintenance: "wrench.and.screwdriver"
        }
    }
}

struct ContentView: View {
    @State private var selection: AppSection = .dashboard

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Codex++ Companion")
            .scrollContentBackground(.hidden)
            .background(Color.appSidebar)
        } detail: {
            Group {
                switch selection {
                case .dashboard:
                    DashboardView()
                case .providerBridge:
                    ProviderBridgeView()
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
                .font(.system(size: 28, weight: .semibold))
            Text(subtitle)
                .font(.callout)
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
        .padding(16)
        .background(Color.appPanel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appBorder)
        )
    }
}
