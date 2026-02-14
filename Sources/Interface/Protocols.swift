protocol SystemStateProtocol {
    func fetchFocusedWindow() -> WindowInfo?
    func listScreens() -> [ScreenInfo]
}

protocol WindowActionProtocol {
    func moveAndResize(windowId: Int, to frame: Rect) -> Bool
}

protocol ConfigRepositoryProtocol {
    func loadConfig() -> AppConfig
    func saveConfig(_ config: AppConfig)
}

protocol OverlayProtocol {
    func showOverlay()
    func hideOverlay()
}
