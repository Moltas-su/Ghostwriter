import AppKit
import SwiftUI

public class SettingsWindowManager {
    public static let shared = SettingsWindowManager()
    private var windowController: NSWindowController?
    
    private init() {}
    
    public func showSettings() {
        if let windowController = windowController, let window = windowController.window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "GhostWriter Settings"
        window.titlebarAppearsTransparent = true
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        let windowController = NSWindowController(window: window)
        self.windowController = windowController
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
