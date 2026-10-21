import Foundation

protocol IgnoredAppsProviding: AnyObject {
    var bundleIdentifiers: [String] { get set }
    func isIgnored(bundleIdentifier: String) -> Bool
    func restoreDefaults()
}
