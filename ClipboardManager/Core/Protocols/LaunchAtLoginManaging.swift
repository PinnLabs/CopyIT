import Foundation

protocol LaunchAtLoginManaging: AnyObject {
    var isEnabled: Bool { get }
    /// True when the login item is registered but waits for the user's approval in System Settings.
    var requiresApproval: Bool { get }
    func enable() throws
    func disable() throws
    func openSystemSettings()
}
