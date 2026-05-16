import SwiftUI

struct HostKitLogoMark: View {
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(Color(red: 0.05, green: 0.50, blue: 1.0), lineWidth: size * 0.07)
                .shadow(color: Color(red: 0.05, green: 0.50, blue: 1.0).opacity(0.72), radius: size * 0.08)
            Path { path in
                path.move(to: CGPoint(x: size * 0.30, y: size * 0.38))
                path.addLine(to: CGPoint(x: size * 0.43, y: size * 0.50))
                path.addLine(to: CGPoint(x: size * 0.30, y: size * 0.62))
            }
            .stroke(Color(red: 0.05, green: 0.50, blue: 1.0), style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round, lineJoin: .round))
            .shadow(color: Color(red: 0.05, green: 0.50, blue: 1.0).opacity(0.75), radius: size * 0.05)
            Path { path in
                path.move(to: CGPoint(x: size * 0.52, y: size * 0.62))
                path.addLine(to: CGPoint(x: size * 0.72, y: size * 0.62))
            }
            .stroke(Color(red: 0.05, green: 0.50, blue: 1.0), style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round))
            .shadow(color: Color(red: 0.05, green: 0.50, blue: 1.0).opacity(0.75), radius: size * 0.05)
            SparkleShape()
                .fill(Color(red: 0.05, green: 0.50, blue: 1.0))
                .frame(width: size * 0.24, height: size * 0.24)
                .shadow(color: Color(red: 0.05, green: 0.50, blue: 1.0).opacity(0.9), radius: size * 0.08)
                .offset(x: size * 0.28, y: -size * 0.28)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Codex HostKit logo")
    }
}

private struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control1: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.midY - rect.height * 0.08), control2: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.midY - rect.height * 0.08))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.midY + rect.height * 0.08), control2: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.midY + rect.height * 0.08))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.midY), control1: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.midY + rect.height * 0.08), control2: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.midY + rect.height * 0.08))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.midY - rect.height * 0.08), control2: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.midY - rect.height * 0.08))
        return path
    }
}

struct FeaturePill: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.07), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.10)))
    }
}
