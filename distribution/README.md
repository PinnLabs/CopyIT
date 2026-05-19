# Distribution

Files for distributing CopyIT via Homebrew Cask.

## Files

- `Casks/copyit.rb` — the Homebrew Cask formula. Copy this into the `PinnLabs/homebrew-tap` repository under `Casks/copyit.rb` and update `version` + `sha256` each release.

## One-time setup (tap repo)

1. Create a new public repo on GitHub: **`PinnLabs/homebrew-tap`** (the name must be `homebrew-tap` for `brew tap PinnLabs/tap` to resolve).
2. Initialize structure:

   ```
   homebrew-tap/
   ├── README.md
   └── Casks/
       └── copyit.rb
   ```

3. Copy `Casks/copyit.rb` from this directory into the tap repo.
4. Commit and push.

End users can then install with:

```sh
brew tap PinnLabs/tap
brew install --cask copyit
```

## Per-release flow

1. Tag the release in this repo: `git tag v1.0.0 && git push origin v1.0.0`
2. GitHub Actions builds the `.app`, zips it, creates a GitHub Release, and prints the SHA256 in the release notes.
3. In `PinnLabs/homebrew-tap`, edit `Casks/copyit.rb`:
   - Update `version "1.0.0"`
   - Update `sha256 "..."` with the value from the release notes
4. Commit and push the tap repo.
5. Users run `brew upgrade --cask copyit`.

## Why this works without paying Apple

- Cask supports ad-hoc-signed `.app` bundles.
- `brew install --cask` automatically strips the `com.apple.quarantine` xattr so Gatekeeper does not block first launch.
- macOS still warns about Input Monitoring permission for the hotkey (expected and required for `CGEventTap`).
