import Foundation

public struct GemmaLocalEngine {
    public static func execute(action: RefinementAction, input: String) -> String {
        let config = ConfigManager.shared
        let modelPath = config.activeModelPath
        
        guard let cliPath = config.llamaCliPath else {
            print("GemmaLocalEngine: llama-cli not found in app bundle")
            return input
        }
        
        guard FileManager.default.fileExists(atPath: modelPath) else {
            print("GemmaLocalEngine: model not found at \(modelPath)")
            return input
        }
        
        let systemPrompt = Prompts.systemPrompt(for: action)
        let formattedPrompt = "<start_of_turn>user\n\(systemPrompt)\n\nText to refine:\n\"\"\"\(input)\"\"\"<end_of_turn>\n<start_of_turn>model\n"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = [
            "-m", modelPath,
            "-p", formattedPrompt,
            "-ngl", "99",              // Offload all layers to Metal / Apple Silicon GPU
            "-c", "2048",
            "--temp", "0.2",
            "-n", "512",
            "--no-display-prompt",
            "--log-disable",           // Suppress llama.cpp internal logging
            "-st"                      // Single-turn mode to avoid interactive REPL hang
        ]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice   // Discard stderr to prevent pipe buffer deadlock
        
        do {
            try process.run()
            
            // Read BEFORE waitUntilExit to prevent 64KB pipe buffer deadlocks
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let rawResult = String(data: outputData, encoding: .utf8) {
                let cleaned = cleanModelOutput(rawResult)
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        } catch {
            print("GemmaLocalEngine execution failed: \(error)")
        }
        
        return input
    }
    
    /// Strip llama.cpp artifacts, REPL formatting, and Gemma control tokens from the raw output
    private static func cleanModelOutput(_ raw: String) -> String {
        var result = raw
        
        // 2. Strip the performance footer first so we only look at the body
        if let footerStart = result.range(of: "\n\n[ Prompt:", options: .backwards) {
            result = String(result[..<footerStart.lowerBound])
        } else if let footerStart = result.range(of: "\n[ Prompt:", options: .backwards) {
            result = String(result[..<footerStart.lowerBound])
        }
        
        // 1. Strip the interactive REPL banner and prompt echo.
        // For long prompts, llama-cli truncates the echo and adds "... (truncated)\n", swallowing our <start_of_turn>model tag.
        if let truncatedStart = result.range(of: "... (truncated)\n", options: .backwards) {
            result = String(result[truncatedStart.upperBound...])
        } else if let modelStart = result.range(of: "<start_of_turn>model\n", options: .backwards) {
            result = String(result[modelStart.upperBound...])
        } else if let modelStart = result.range(of: "<start_of_turn>model", options: .backwards) {
            result = String(result[modelStart.upperBound...])
        }
        
        // Remove Gemma special tokens that may leak into output
        let tokensToStrip = [
            "<end_of_turn>",
            "<start_of_turn>",
            "<eos>",
            "<bos>",
            "model\n",  // Sometimes the model role tag leaks
        ]
        
        for token in tokensToStrip {
            result = result.replacingOccurrences(of: token, with: "")
        }
        
        // Remove common LLM preambles that small models tend to add
        let preambles = [
            "Here is the corrected text:\n",
            "Here is the rewritten text:\n",
            "Here's the corrected text:\n",
            "Here's the rewritten text:\n",
            "Corrected text:\n",
            "Rewritten text:\n",
        ]
        
        for preamble in preambles {
            if result.hasPrefix(preamble) {
                result = String(result.dropFirst(preamble.count))
            }
        }
        
        // Strip surrounding triple-quotes if the model mirrors the input format
        if result.hasPrefix("\"\"\"") && result.hasSuffix("\"\"\"") {
            result = String(result.dropFirst(3).dropLast(3))
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
