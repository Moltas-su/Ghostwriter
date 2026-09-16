import AppKit
let pboard = NSPasteboard.general
pboard.clearContents()
pboard.setString("This is a test with speling errors.", forType: .string)
let success = NSPerformService("GhostWriter: Proofread & Fix", pboard)
print("Service invoked: \(success)")
if let result = pboard.string(forType: .string) {
    print("Result: \(result)")
}
