/// How an Emacs-style split shrinks a window inside its own frame.
enum SplitDirection: Equatable {
    /// Like Emacs `split-window-below` (`C-x 2`): keep the top half.
    case below
    /// Like Emacs `split-window-right` (`C-x 3`): keep the left half.
    case right
}
