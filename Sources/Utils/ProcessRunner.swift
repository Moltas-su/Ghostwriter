import Foundation

public struct ProcessRunner {
    public static func run(executableURL: URL, arguments: [String], input: String?) throws -> String? {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        
        if input != nil {
            process.standardInput = inputPipe
        }
        process.standardOutput = outputPipe
        
        try process.run()
        
        if let inputString = input, let data = inputString.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
            try inputPipe.fileHandleForWriting.close()
        }
        
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: outputData, encoding: .utf8)
    }
}
