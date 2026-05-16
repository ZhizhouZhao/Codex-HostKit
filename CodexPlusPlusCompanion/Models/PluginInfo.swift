import Foundation

struct PluginInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let hasManifest: Bool
    let version: String?
}
