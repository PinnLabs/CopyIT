import Foundation

protocol IgnoredAppsProviding: AnyObject {
    func isIgnored(bundleIdentifier: String) -> Bool
}
