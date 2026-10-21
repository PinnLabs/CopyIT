# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
