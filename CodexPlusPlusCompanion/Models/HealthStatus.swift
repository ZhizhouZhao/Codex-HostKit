import SwiftUI

enum HealthLevel: String {
    case ok = "正常"
    case warning = "警告"
    case error = "错误"

    var color: Color {
        switch self {
        case .ok: .green
        case .warning: .yellow
        case .error: .red
        }
    }
}

struct HealthStatus: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let level: HealthLevel
}
