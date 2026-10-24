import os

private let logger = Logger(
    subsystem: "com.garaemon.BisectWindow", category: "debug"
)

/// Writes `message` to the unified log in Debug builds and does nothing in
/// Release builds. Read the output with `make logs`.
func debugLog(_ message: @autoclosure () -> String) {
    // Messages carry window frames and pids, which must stay out of a
    // Release user's log.
    #if DEBUG
    let text = message()
    logger.debug("\(text, privacy: .public)")
    #endif
}
