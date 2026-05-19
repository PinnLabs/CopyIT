import Foundation

protocol HotkeyRegistering: AnyObject {
    var onHotkeyTriggered: (() -> Void)? { get set }
    func register()
    func unregister()
}
