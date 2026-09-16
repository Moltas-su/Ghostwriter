import AppKit
import Sparkle

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!
    private var serviceProvider: ServiceProvider!
    private var updaterController: SPUStandardUpdaterController!
    
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Sparkle
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Initialize Menu Bar
        menuBarController = MenuBarController(updaterController: updaterController)
        
        // Register macOS Services
        serviceProvider = ServiceProvider()
        NSApplication.shared.servicesProvider = serviceProvider
        
        // Ensure services are updated
        NSUpdateDynamicServices()
        
        // Check onboarding state
        if !ConfigManager.shared.hasCompletedOnboarding {
            OnboardingWindowManager.shared.showOnboarding()
        }
    }
    
    public func applicationWillTerminate(_ aNotification: Notification) {
        // Teardown code here.
    }
}
