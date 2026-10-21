# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- App icon, menu bar icon and brand assets.
- Skip clipboard items that password managers mark as concealed, transient or auto-generated.
- Skip items copied while an ignored app is frontmost (Keychain Access, Passwords, 1Password, Bitwarden by default).
- Pause capture from the menu bar (15 minutes, 1 hour, or until resumed).
- Settings window with launch at login and history size (25 to 200 items).
- Issue and PR templates, security policy and code of conduct.
- Edit the ignored apps list in Settings → Privacy.
- Automatically delete items older than 1, 7, 30 or 90 days.
- Optionally clear the history when quitting CopyIT.

### Changed

- The global shortcut no longer requires Input Monitoring or Accessibility permission.
- Launch at login is now opt-in instead of always on.

### Fixed

- Copying large images no longer freezes the UI: images are processed off the main thread.
- Arrow keys, return and escape work while the search field is focused; delete the selected item with `⌘⌫`.

### Removed

- Unused Apple Events entitlement and usage description.

## [1.1.0] - 2026-08-04

### Added

- Support for capturing and restoring clipboard images.

### Changed

- Clipboard images are now stored disk-backed instead of in `UserDefaults`.

## [1.0.0] - 2026-05-18

### Added

- Initial release: native macOS menu bar clipboard manager.
- Tracks the last 50 clipboard entries (text, URLs, images).
- Search with live filtering, keyboard navigation, global hotkey (`⌥Space`).
- Launch at login support.

[Unreleased]: https://github.com/PinnLabs/CopyIT/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/PinnLabs/CopyIT/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/PinnLabs/CopyIT/releases/tag/v1.0.0
