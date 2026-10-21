import Carbon.HIToolbox
import Foundation

final class HotkeyManager: HotkeyRegistering {
    var onHotkeyTriggered: (() -> Void)?

    // "CPIT" as a FourCharCode, so the handler only reacts to our own hot key.
    static let signature: FourCharCode = 0x4350_4954
    static let hotKeyID: UInt32 = 1

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    deinit { unregister() }

    func register() {
        guard hotKeyRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        guard handlerStatus == noErr else {
            AppLogger.hotkey.error("InstallEventHandler failed with OSStatus \(handlerStatus, privacy: .public)")
            return
        }

        let id = EventHotKeyID(signature: Self.signature, id: Self.hotKeyID)
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else {
            AppLogger.hotkey.error("RegisterEventHotKey for ⌥Space failed with OSStatus \(status, privacy: .public)")
            unregister()
            return
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        hotKeyRef = nil
        eventHandlerRef = nil
    }

    var isRegistered: Bool { hotKeyRef != nil }

    @discardableResult
    func handleHotKeyPressed(id: EventHotKeyID) -> Bool {
        guard id.signature == Self.signature, id.id == Self.hotKeyID else { return false }
        DispatchQueue.main.async { [weak self] in
            self?.onHotkeyTriggered?()
        }
        return true
    }
}

private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var id = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &id
    )
    guard status == noErr else { return status }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    return manager.handleHotKeyPressed(id: id) ? noErr : OSStatus(eventNotHandledErr)
}
