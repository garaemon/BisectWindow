import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLog("[BisectWindow] applicationDidFinishLaunching")
        let appCoordinator = AppCoordinator()
        appCoordinator.start()
        coordinator = appCoordinator
        debugLog("[BisectWindow] coordinator started")
    }

    func applicationWillTerminate(_ notification: Notification) {
        debugLog("[BisectWindow] applicationWillTerminate")
        coordinator?.stop()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
