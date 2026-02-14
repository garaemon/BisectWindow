# BisectWindow

A keyboard-driven window manager for macOS. Inspired by Emacs keybindings, it enables context-aware window tiling and screen traversal without leaving the keyboard.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later
- [mise](https://mise.jdx.dev/) (for tool version management)

## Setup

```bash
# Install tools (XcodeGen)
mise install

# Generate Xcode project
make generate
```

## Build

```bash
# Build from command line
make build

# Or open the generated .xcodeproj in Xcode and build (Cmd+B)
```

## Test

```bash
make test
```

## Project Structure

```
Sources/
  App/            -- Application entry point
  Domain/         -- Core logic (pure Swift, no OS dependencies)
    Models/       -- Data models (Rect, WindowInfo, AppConfig)
  Interface/      -- Protocol definitions
  Infrastructure/ -- OS-level implementations (Accessibility, Persistence)
  UI/             -- SwiftUI views (Settings, Overlay)
Tests/
  LogicTests/     -- Unit tests for Domain layer
```
