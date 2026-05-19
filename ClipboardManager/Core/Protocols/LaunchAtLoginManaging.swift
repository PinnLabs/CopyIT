import Foundation

protocol LaunchAtLoginManaging: AnyObject {
    var isEnabled: Bool { get }
    func enable() throws
    func disable() throws
}
