import AppKit
import SwiftUI

@main
struct RepoHubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = RepoModel()

    var body: some Scene {
        WindowGroup("RepoHub", id: "main") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 440, minHeight: 520)
        }
        .defaultSize(width: 560, height: 720)
        // Widget clicks arrive as repohub:// URLs; don't open a window for them.
        .handlesExternalEvents(matching: [])
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let launchDate = Date()

    func application(_ application: NSApplication, open urls: [URL]) {
        let targets = urls.compactMap(PinStore.target(from:))
        guard !targets.isEmpty else { return }
        targets.forEach { NSWorkspace.shared.open($0) }

        // Launched only to forward a widget click: stay out of the way.
        if Date().timeIntervalSince(launchDate) < 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NSApp.windows.forEach { $0.close() }
                NSApp.hide(nil)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
