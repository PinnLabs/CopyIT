# Releasing CopyIT

Maintainer guide. End users do not need this.

## Pre-flight checklist

- [ ] All tests pass locally: `make test`
- [ ] Lint is clean: `make lint`
- [ ] `master` is green in CI
- [ ] README updated for any user-facing changes
- [ ] No uncommitted changes: `git status` clean

## Cut a release

The app version comes from the tag: there's nothing to bump in `project.yml` or `Info.plist`.

1. In `CHANGELOG.md`, rename `## [Unreleased]` to `## [1.2.0] - YYYY-MM-DD`, add a new empty
   `## [Unreleased]` above it, and update the compare links at the bottom.
2. Commit and push:

   ```sh
   git commit -am "chore: release 1.2.0"
   git push
   ```

3. Tag and push the tag:

   ```sh
   git tag v1.2.0
   git push origin v1.2.0
   ```

GitHub Actions (`.github/workflows/release.yml`) runs on the tag and:

1. Fails early if `CHANGELOG.md` has no `## [1.2.0]` section
2. Builds Release-config `ClipboardManager.app` on `macos-15`, with `MARKETING_VERSION` set to the
   tag version and `CURRENT_PROJECT_VERSION` set to the workflow run number
3. Zips it with `ditto` (preserves resource forks)
4. Computes SHA256
5. Creates a GitHub Release with the zip attached
6. Embeds the SHA256 in the release notes

## Update the Homebrew Cask

After the release artifacts publish:

1. Open `PinnLabs/homebrew-tap` repo
2. Edit `Casks/copyit.rb`:
   - Bump `version "1.0.0"` to the new version
   - Replace `sha256 "..."` with the value from the release notes
3. Commit:

   ```sh
   git commit -am "copyit 1.0.0"
   git push
   ```

Users get the update with `brew upgrade --cask copyit`.

## Manual / dry-run release

Useful before the first GitHub Release:

```sh
make release VERSION=1.0.0 BUILD=1
# Artifacts land in dist/
# dist/CopyIT-1.0.0.zip
# dist/CopyIT-1.0.0.zip.sha256
```

Upload the zip to a draft GitHub Release manually, paste the SHA256 into the cask.

## Versioning

[Semantic Versioning](https://semver.org/):

- **MAJOR** — breaking UX or storage format change
- **MINOR** — new features, backward compatible
- **PATCH** — bug fixes only

Tags always prefixed with `v` (e.g., `v1.2.3`).

## Why no Apple signing/notarization

Apple Developer Program is $99/yr. Cask handles the Gatekeeper quarantine bit automatically, so ad-hoc-signed builds install cleanly via `brew install --cask`. Manual zip downloads still trigger the Gatekeeper prompt — README covers the bypass.

If notarization is added later: extend `release.yml` with `xcrun notarytool submit` + `xcrun stapler staple` steps and store the App Store Connect API key as a GitHub Actions secret.
