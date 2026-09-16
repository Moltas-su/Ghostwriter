import AppKit
import SwiftUI

public class OnboardingWindowManager {
    public static let shared = OnboardingWindowManager()
    private var windowController: NSWindowController?
    
    private init() {}
    
    public func showOnboarding() {
        if let windowController = windowController, let window = windowController.window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingController = NSHostingController(rootView: OnboardingView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "Welcome to GhostWriter"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        // Prevent closing via red button
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        let windowController = NSWindowController(window: window)
        self.windowController = windowController
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func closeOnboarding() {
        windowController?.close()
        windowController = nil
    }
}
