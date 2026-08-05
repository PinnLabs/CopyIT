cask "copyit" do
  version "1.1.0"
  sha256 "a8ab1947239a7fcdcdb8696d2d70b1b8b7906340df4094acef5ad985b84aff08"

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
