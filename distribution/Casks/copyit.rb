cask "copyit" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE"

  url "https://github.com/PinnLabs/CopyIT/releases/download/v#{version}/CopyIT-#{version}.zip"
  name "CopyIT"
  desc "Native macOS menu bar clipboard manager"
  homepage "https://github.com/PinnLabs/CopyIT"

  depends_on macos: ">= :sonoma"

  app "ClipboardManager.app"

  zap trash: [
    "~/Library/Preferences/com.copyit.ClipboardManager.plist",
    "~/Library/Caches/com.copyit.ClipboardManager",
    "~/Library/Application Support/com.copyit.ClipboardManager",
    "~/Library/HTTPStorages/com.copyit.ClipboardManager",
  ]
end
