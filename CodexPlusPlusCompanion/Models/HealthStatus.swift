import SwiftUI

enum HealthLevel: String {
    case ok = "OK"
    case warning = "Warning"
    case error = "Error"

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
