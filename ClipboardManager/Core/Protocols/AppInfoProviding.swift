import AppKit

protocol AppInfoProviding {
    func appInfo(bundleIdentifier: String) -> (name: String, icon: NSImage?)
}

struct WorkspaceAppInfo: AppInfoProviding {
    /// Falls back to the bundle ID and no icon when the app isn't installed.
    func appInfo(bundleIdentifier: String) -> (name: String, icon: NSImage?) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return (bundleIdentifier, nil)
        }
        var name = FileManager.default.displayName(atPath: url.path)
        // displayName keeps ".app" when the user shows all file extensions in Finder.
        if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
        return (name, NSWorkspace.shared.icon(forFile: url.path))
    }
}
