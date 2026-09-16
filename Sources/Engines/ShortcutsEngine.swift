import Foundation
import AppKit

public struct ShortcutsEngine {
    public static func execute(action: RefinementAction, input: String) -> String {
        // Ensure the general clipboard has the input text for "Get Clipboard"
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.setString(input, forType: .string)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", "GhostWriter-\(action.identifier)", "--output-type", "public.plain-text"]
        
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        
        do {
            try process.run()
            if let data = input.data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(data)
                try inputPipe.fileHandleForWriting.close()
            }
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !result.isEmpty {
                return result
            }
        } catch {
            print("Shortcuts execution failed: \(error)")
        }
        
        return input // Fallback to original text on failure
    }
}
