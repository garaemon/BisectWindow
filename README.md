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

# Set your Apple development team for code signing
cp Configs/Signing.local.xcconfig.example Configs/Signing.local.xcconfig
# Then replace YOUR_TEAM_ID in Configs/Signing.local.xcconfig

# Generate Xcode project
make generate
```

Debug builds are signed with your Apple Development certificate so that the
Accessibility permission survives rebuilds. `make test` needs no team ID.

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

## Logs

Debug builds write to the unified log. Stream them with:

```bash
make logs
```

## Project Structure

```
Sources/
  App/            -- Application entry point
  Domain/         -- Core logic (pure Swift, no OS dependencies)
    Models/       -- Data models (Rect, WindowInfo, AppConfig)
  Interface/      -- Protocol definitions
  Infrastructure/ -- OS-level implementations (Accessibility, HotKey, Logging, Persistence)
  UI/             -- SwiftUI views (Settings, Overlay)
Tests/
  LogicTests/     -- Unit tests that need no Accessibility permission
    Support/      -- Shared fixtures
```
