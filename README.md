# CopyIT — ClipboardManager

<video src=".github/assets/demo.mp4" controls width="1024"></video>

Native macOS menu bar clipboard manager. Open source, MIT-licensed.

## Features (v1.0)

- Lives in the menu bar — no Dock icon, no `⌘Tab` clutter (`LSUIElement`).
- Tracks the last 50 clipboard entries (text, URLs, and images).
- Search with live filtering, case-insensitive.
- Keyboard navigation: arrows to move, `↩` to copy, `⌫` to delete, `esc` to close.
- Global hotkey `⌥Space` to toggle the popover from anywhere.
- Right-click the status bar icon for quick actions (Open, Clear, Quit).
- Launches at login (`SMAppService`).
- Persists history metadata in `UserDefaults` and image payloads in Application Support.

## Install

### Homebrew (recommended)

```sh
brew tap PinnLabs/tap
brew install --cask copyit
```

### Manual download

1. Grab the latest `CopyIT-x.y.z.zip` from [Releases](https://github.com/PinnLabs/CopyIT/releases).
2. Unzip and drag `ClipboardManager.app` to `/Applications`.
3. First launch — right-click → **Open** to bypass Gatekeeper (the app is ad-hoc signed), or run:

   ```sh
   xattr -dr com.apple.quarantine /Applications/ClipboardManager.app
   ```

4. Grant **Input Monitoring** permission when prompted (System Settings → Privacy & Security → Input Monitoring) so `⌥Space` works.

### Build from source

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (Swift 5.9+) — only needed if building from source
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — only needed if building from source

## Quick start

```bash
brew install xcodegen
make setup           # generates Xcode project
make run             # build + launch
make test            # run unit tests
```

Or open in Xcode after `make generate` and use `⌘R` / `⌘U`.

## Permissions

The global hotkey relies on `CGEventTap`, which requires **Input Monitoring** permission. On first launch macOS prompts to grant access — open System Settings → Privacy & Security → Input Monitoring and enable ClipboardManager.

## Project structure

```
ClipboardManager/
├── App/                  # Entry point + AppDelegate (composition root)
├── Core/
│   ├── Protocols/        # ClipboardMonitoring, ClipboardStoring,
│   │                     # HotkeyRegistering, LaunchAtLoginManaging
│   ├── Models/           # ClipboardItem, ClipboardItemType
│   ├── Services/         # ClipboardMonitor, HotkeyManager,
│   │                     # LaunchAtLoginService, AppLogger
│   └── UseCases/         # Fetch, Copy, Delete, Clear
├── UI/
│   ├── StatusBar/        # NSStatusItem + NSPopover + right-click menu
│   └── Popover/          # SwiftUI views + @Observable PopoverViewModel
├── Infrastructure/
│   └── Persistence/      # UserDefaultsStore (concrete ClipboardStoring)
└── Resources/            # Info.plist, Assets.xcassets, entitlements
Tests/
├── CoreTests/            # Store, monitor, use cases, hotkey, launch-at-login
│   └── Mocks/            # Protocol-conforming mocks
└── UITests/              # PopoverViewModel
```

## Architecture

Clean Architecture + SOLID. The composition root is `AppDelegate.applicationDidFinishLaunching(_:)` — the only place that wires concrete implementations. UI never touches `NSPasteboard` or `UserDefaults` directly.

```
[ClipboardMonitor] --onNewItem--> [AppDelegate] --save--> [Store]
                                       |
                                       v
                                  [ViewModel] --refresh--> SwiftUI
                                       ^
[HotkeyManager] --⌥Space--> [StatusBar] --togglePopover-->|
```

Logging uses `OSLog.Logger` exposed via `AppLogger.<category>`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
