import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation

final class HotkeyManager: HotkeyRegistering {
    var onHotkeyTriggered: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private static let spaceKeyCode: CGKeyCode = CGKeyCode(kVK_Space)

    deinit { unregister() }

    func register() {
        guard eventTap == nil else { return }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyCallback,
            userInfo: selfPointer
        ) else {
            AppLogger.hotkey.error("Failed to create event tap. Input Monitoring permission missing?")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    fileprivate func reenable() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    fileprivate func handle(event: CGEvent) -> Bool {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard keyCode == Self.spaceKeyCode else { return false }

        let flags = event.flags
        let hasOption = flags.contains(.maskAlternate)
        let hasCommand = flags.contains(.maskCommand)
        let hasControl = flags.contains(.maskControl)
        let hasShift = flags.contains(.maskShift)

        guard hasOption, !hasCommand, !hasControl, !hasShift else { return false }

        DispatchQueue.main.async { [weak self] in
            self?.onHotkeyTriggered?()
        }
        return true
    }
}

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let info = userInfo {
            let manager = Unmanaged<HotkeyManager>.fromOpaque(info).takeUnretainedValue()
            manager.reenable()
        }
        return Unmanaged.passUnretained(event)
    }

    guard let info = userInfo else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(info).takeUnretainedValue()
    if manager.handle(event: event) {
        return nil
    }
    return Unmanaged.passUnretained(event)
}
