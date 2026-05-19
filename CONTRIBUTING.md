# Contributing to ClipboardManager

Thanks for your interest. This guide covers local setup, conventions, and the PR flow.

## Local setup

```bash
brew install xcodegen
xcodegen generate
open ClipboardManager.xcodeproj
```

Or via Makefile: `make setup`.

## Build & test

| Action | Make target | Xcode |
|--------|-------------|-------|
| Generate project | `make generate` | — |
| Build (Debug) | `make build` | `⌘B` |
| Run | `make run` | `⌘R` |
| Unit tests | `make test` | `⌘U` |
| Clean | `make clean` | `⇧⌘K` |

## Architecture

Clean Architecture + SOLID. Composition root lives in `AppDelegate`. New features should:

1. Add a protocol to `Core/Protocols/` if it represents a capability.
2. Implement under `Core/Services/` or `Infrastructure/`.
3. Expose business operations as a `UseCase` with a single `execute(...)` method.
4. Inject dependencies from `AppDelegate` — never via singletons (except Apple-provided ones like `NSPasteboard.general`).
5. Cover with unit tests using mocks in `Tests/CoreTests/Mocks/`.

## Code conventions

- Swift 5.9+, `final` on every non-subclassed class.
- No force-unwraps (`!`, `try!`, `as!`) in production code. Use `guard let` / `if let`.
- Prefer `struct` for value types and models.
- `[weak self]` in escaping closures that capture `self`.
- No magic numbers — declare as `static let`.
- No singletons except Apple APIs.
- Comments explain **why**, not **what**. Skip comments that restate the code.
- File organization: `// MARK: -` to delineate sections.
- Functions ≤ 20 lines; extract when longer.
- UI never touches `NSPasteboard` or `UserDefaults` directly — go through a use case.
- Logs via `AppLogger.<category>` (`os.Logger`), never `print`/`NSLog`.

## Tests

- Each protocol gets a mock under `Tests/CoreTests/Mocks/`.
- Test names follow `test_<scenario>_<expected>` (Given/When/Then implied).
- Prefer fast, deterministic unit tests. UI/integration tests are optional but welcome.

## Commits & PRs

- Conventional commits encouraged (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
- One logical change per PR. Keep diffs reviewable.
- Update `README.md` if behavior or setup changes.
- Add tests for new logic; bug fixes should include a regression test.

## License

By contributing you agree your work is licensed under the MIT License (see `LICENSE`).
