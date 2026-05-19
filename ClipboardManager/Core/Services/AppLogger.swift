import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = "com.copyit.ClipboardManager"

    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    static let monitor = Logger(subsystem: subsystem, category: "monitor")
    static let store = Logger(subsystem: subsystem, category: "store")
    static let launchAtLogin = Logger(subsystem: subsystem, category: "launchAtLogin")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
