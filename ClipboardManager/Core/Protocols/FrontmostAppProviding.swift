import AppKit

protocol FrontmostAppProviding {
    var frontmostBundleIdentifier: String? { get }
}

struct WorkspaceFrontmostApp: FrontmostAppProviding {
    var frontmostBundleIdentifier: String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}
