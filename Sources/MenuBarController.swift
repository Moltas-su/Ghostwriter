import AppKit

public class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    public override init() {
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
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit GhostWriter", action: #selector(quitApp), keyEquivalent: "q")
        
        for item in menu.items {
            item.target = self
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
