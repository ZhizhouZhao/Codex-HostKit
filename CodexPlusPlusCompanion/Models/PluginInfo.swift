import Foundation

struct PluginInfo: Identifiable {
    var id: String { path.path }
    let name: String
    let displayName: String
    let path: URL
    let hasManifest: Bool
    let version: String?
    let iconURL: URL?
    let brandColor: String?
    let category: String?
}
