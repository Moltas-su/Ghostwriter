import AppKit

@objc public class ServiceProvider: NSObject {
    @objc func proofreadService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        handleService(pboard: pboard, action: .proofread, error: error)
    }
    
    @objc func rewriteService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        handleService(pboard: pboard, action: .rewrite, error: error)
    }
    
    private func handleService(pboard: NSPasteboard, action: RefinementAction, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let input = pboard.string(forType: .string), !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let output = RefinementEngineRouter.shared.refineSync(text: input, action: action)
        
        if output == input {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Refinement Failed"
                alert.informativeText = self.errorMessage(for: action)
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            return
        }
        
        pboard.clearContents()
        pboard.setString(output, forType: .string)
    }
    
    /// Provides a backend-specific error message to help users troubleshoot.
    private func errorMessage(for action: RefinementAction) -> String {
        let config = ConfigManager.shared
        
        switch config.activeBackend {
        case .appleShortcuts:
            return "The Shortcuts backend failed to refine the text. Ensure 'GhostWriter-\(action.identifier)' exists in your Shortcuts app."
        case .localModel:
            if config.llamaCliPath == nil {
                return "The llama-cli inference engine was not found in the app bundle. Please reinstall GhostWriter."
            }
            if !config.isGemmaModelDownloaded {
                return "The \(config.selectedModelSize.displayName) model is not downloaded. Open GhostWriter Settings and click 'Download Model'."
            }
            return "The local model failed to refine the text. The model may have produced unexpected output. Try again or switch to a different backend in Settings."
        }
    }
}
