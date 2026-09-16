import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!
    private var serviceProvider: ServiceProvider!
    
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Menu Bar
        menuBarController = MenuBarController()
        
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
