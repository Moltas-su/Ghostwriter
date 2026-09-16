import Foundation
import AppKit

public class ShortcutManager {
    public static let shared = ShortcutManager()
    
    let requiredShortcuts = [
        "GhostWriter-Proofread",
        "GhostWriter-Rewrite"
    ]
    
    private init() {}
    
    public func getMissingShortcuts() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let installed = output.components(separatedBy: .newlines)
                
                var missingShortcuts: [String] = []
                for req in requiredShortcuts {
                    if !installed.contains(req) {
                        missingShortcuts.append(req)
                    }
                }
                return missingShortcuts
            }
        } catch {
            print("Failed to list shortcuts: \(error)")
        }
        
        // If we fail to list, assume they are missing just in case
        return requiredShortcuts
    }
    
    public func installBundledShortcuts(missing: [String]) {
        for shortcutName in missing {
            guard let url = Bundle.main.url(forResource: shortcutName, withExtension: "shortcut", subdirectory: "Shortcuts") else {
                print("Missing bundled shortcut: \(shortcutName).shortcut")
                continue
            }
            NSWorkspace.shared.open(url)
        }
    }
    
    public func installAllShortcuts() {
        installBundledShortcuts(missing: requiredShortcuts)
    }
}
