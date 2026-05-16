import SwiftUI

@main
struct CodexPlusPlusCompanionApp: App {
    @StateObject private var notifier = AppNotifier()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notifier)
                .frame(minWidth: 760, idealWidth: 900, minHeight: 520, idealHeight: 620)
        }
        .defaultSize(width: 900, height: 620)
        .windowStyle(.hiddenTitleBar)
    }
}
