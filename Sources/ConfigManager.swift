import Foundation

// MARK: - Backend Type (extensible for future BYOK API key support)

public enum BackendType: String, CaseIterable, Identifiable {
    case appleShortcuts = "shortcuts"
    case localModel = "local"
    // Future: case openAI = "openai"
    // Future: case anthropic = "anthropic"
    // Future: case custom = "custom"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .appleShortcuts: return "Apple Intelligence (Shortcuts)"
        case .localModel: return "Local AI Model"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .appleShortcuts:
            return "Powered by macOS Apple Intelligence. Requires GhostWriter-Proofread and GhostWriter-Rewrite to be installed in your Shortcuts app."
        case .localModel:
            return "Powered by an embedded, privacy-first local AI model. Completely offline and secure. Requires a one-time model download."
        }
    }
}

// MARK: - Local Model Size

public enum LocalModelSize: String, CaseIterable, Identifiable {
    case oneB = "1b"
    case fourB = "4b"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .oneB: return "Gemma 3 1B"
        case .fourB: return "Gemma 3 4B"
        }
    }
    
    public var sizeDescription: String {
        switch self {
        case .oneB: return "~750 MB download · Fastest · Good for basic corrections"
        case .fourB: return "~2.5 GB download · Better quality · Recommended"
        }
    }
    
    public var warningText: String? {
        switch self {
        case .oneB: return "⚠️ The 1B model is very small and may struggle with complex tasks or non-English languages. It is recommended to use the 4B model or the default Apple Intelligence backend for better results."
        case .fourB: return nil
        }
    }
    
    public var fileName: String {
        switch self {
        case .oneB: return "gemma-3-1b-it-Q4_K_M.gguf"
        case .fourB: return "gemma-3-4b-it-Q4_K_M.gguf"
        }
    }
    
    public var downloadURL: URL {
        switch self {
        case .oneB:
            return URL(string: "https://huggingface.co/lmstudio-community/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf")!
        case .fourB:
            return URL(string: "https://huggingface.co/lmstudio-community/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf")!
        }
    }
}

// MARK: - Config Manager

public class ConfigManager {
    public static let shared = ConfigManager()
    
    private let defaults = UserDefaults.standard
    private let backendKey = "ActiveBackend"
    private let modelSizeKey = "LocalModelSize"
    
    // Legacy key for backward compatibility
    private let legacyGemmaKey = "UseGemmaBackend"
    
    private init() {
        migrateIfNeeded()
    }
    
    /// Migrate from the old boolean UseGemmaBackend key to the new enum-based system
    private func migrateIfNeeded() {
        // If the new key already exists, no migration needed
        if defaults.string(forKey: backendKey) != nil { return }
        
        // Check if old boolean key was set to true
        if defaults.bool(forKey: legacyGemmaKey) {
            defaults.set(BackendType.localModel.rawValue, forKey: backendKey)
        }
        // Otherwise leave nil — activeBackend getter defaults to .appleShortcuts
    }
    
    // MARK: - Active Backend
    
    public var activeBackend: BackendType {
        get {
            if let raw = defaults.string(forKey: backendKey),
               let backend = BackendType(rawValue: raw) {
                return backend
            }
            return .appleShortcuts
        }
        set {
            defaults.set(newValue.rawValue, forKey: backendKey)
            // Keep legacy key in sync for any code that still reads it
            defaults.set(newValue == .localModel, forKey: legacyGemmaKey)
        }
    }
    
    // MARK: - Onboarding
    
    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "HasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "HasCompletedOnboarding") }
    }
    
    /// Convenience: true when the local model backend is active.
    /// Kept for backward compatibility with existing code paths.
    public var useGemmaBackend: Bool {
        get { activeBackend == .localModel }
        set { activeBackend = newValue ? .localModel : .appleShortcuts }
    }
    
    // MARK: - Local Model Size
    
    public var selectedModelSize: LocalModelSize {
        get {
            if let raw = defaults.string(forKey: modelSizeKey),
               let size = LocalModelSize(rawValue: raw) {
                return size
            }
            return .oneB  // Default to smaller model
        }
        set {
            defaults.set(newValue.rawValue, forKey: modelSizeKey)
        }
    }
    
    // MARK: - Model Paths
    
    public var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("GhostWriter/models")
    }
    
    public func modelPath(for size: LocalModelSize) -> String {
        return modelsDirectory.appendingPathComponent(size.fileName).path
    }
    
    public var activeModelPath: String {
        return modelPath(for: selectedModelSize)
    }
    
    public func isModelDownloaded(size: LocalModelSize) -> Bool {
        return FileManager.default.fileExists(atPath: modelPath(for: size))
    }
    
    /// Checks whether the currently selected model is downloaded
    public var isGemmaModelDownloaded: Bool {
        return isModelDownloaded(size: selectedModelSize)
    }
    
    public var llamaCliPath: String? {
        return Bundle.main.path(forResource: "llama-cli", ofType: nil)
    }
    
    /// Ensure the models directory exists
    public func ensureModelsDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: modelsDirectory.path) {
            try? fm.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// Delete a downloaded model to free disk space
    public func deleteModel(size: LocalModelSize) -> Bool {
        let path = modelPath(for: size)
        guard FileManager.default.fileExists(atPath: path) else { return true }
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            print("Failed to delete model: \(error)")
            return false
        }
    }
}
