import Foundation

public enum RefinementAction: String, CaseIterable {
    case proofread = "Proofread & Fix"
    case rewrite = "Rewrite"
    
    public var identifier: String {
        switch self {
        case .proofread: return "Proofread"
        case .rewrite: return "Rewrite"
        }
    }
}

/// Routes refinement requests to the active backend engine.
///
/// The same two context-menu actions ("Proofread & Fix" and "Rewrite")
/// are used regardless of which backend is active. This router reads the
/// user's preference from ConfigManager and dispatches accordingly.
///
/// Architecture note: When adding a new backend (e.g. BYOK OpenAI),
/// add a new case to `BackendType` in ConfigManager and a corresponding
/// branch here. No changes needed to ServiceProvider or Info.plist.
public class RefinementEngineRouter {
    public static let shared = RefinementEngineRouter()
    
    private init() {}
    
    public func refineSync(text: String, action: RefinementAction) -> String {
        let backend = ConfigManager.shared.activeBackend
        
        switch backend {
        case .appleShortcuts:
            return ShortcutsEngine.execute(action: action, input: text)
        case .localModel:
            return GemmaLocalEngine.execute(action: action, input: text)
        // Future BYOK backends would be added here:
        // case .openAI:
        //     return OpenAIEngine.execute(action: action, input: text, apiKey: ConfigManager.shared.openAIKey)
        }
    }
}
