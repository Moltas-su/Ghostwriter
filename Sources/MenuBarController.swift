import AppKit
import Sparkle

public class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var updaterController: SPUStandardUpdaterController
    
    public init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
        super.init()
        setupMenu()
    }
    
    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "GhostWriter")
        }
        
        menu = NSMenu(title: "GhostWriter")
        
        menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        
        let checkForUpdatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)), keyEquivalent: "")
        checkForUpdatesItem.target = updaterController
        menu.addItem(checkForUpdatesItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit GhostWriter", action: #selector(quitApp), keyEquivalent: "q")
        
        for item in menu.items {
            if item.target == nil {
                item.target = self
            }
        }
        
        statusItem.menu = menu
    }
    
    @objc private func openSettings() {
        SettingsWindowManager.shared.showSettings()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }
}
