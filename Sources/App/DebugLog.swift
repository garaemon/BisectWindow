import Foundation

private let logFileHandle: FileHandle? = {
    let path = "/tmp/BisectWindow.log"
    FileManager.default.createFile(atPath: path, contents: nil)
    return FileHandle(forWritingAtPath: path)
}()

func debugLog(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    if let data = line.data(using: .utf8) {
        logFileHandle?.seekToEndOfFile()
        logFileHandle?.write(data)
    }
    // Also print to stderr for Console.app
    fputs(line, stderr)
}
