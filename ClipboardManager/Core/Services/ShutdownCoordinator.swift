import Foundation

/// Clears the history on quit when the user asks for it, and on the next launch if the app was
/// force-quit or crashed before it could.
final class ShutdownCoordinator {
    static let pendingClearKey = "com.copyit.shutdown.pendingClear"
    static let didTerminateCleanlyKey = "com.copyit.shutdown.didTerminateCleanly"

    private let defaults: UserDefaults
    private let preferences: PreferencesStoring
    private let clearHistoryUseCase: ClearHistoryUseCase

    init(defaults: UserDefaults = .standard, preferences: PreferencesStoring, clearHistoryUseCase: ClearHistoryUseCase) {
        self.defaults = defaults
        self.preferences = preferences
        self.clearHistoryUseCase = clearHistoryUseCase
    }

    func handleLaunch() {
        let hadPendingClear = defaults.bool(forKey: Self.pendingClearKey)
        let didTerminateCleanly = defaults.bool(forKey: Self.didTerminateCleanlyKey)
        defaults.removeObject(forKey: Self.didTerminateCleanlyKey)

        if preferences.clearsHistoryOnQuit, hadPendingClear || !didTerminateCleanly {
            AppLogger.store.info("Clearing history left over from an unclean shutdown")
            clearHistoryUseCase.execute()
        }
        defaults.removeObject(forKey: Self.pendingClearKey)
    }

    func handleTerminate() {
        if preferences.clearsHistoryOnQuit {
            // Set first so a crash mid-clear still clears on the next launch.
            defaults.set(true, forKey: Self.pendingClearKey)
            clearHistoryUseCase.execute()
            defaults.removeObject(forKey: Self.pendingClearKey)
        }
        defaults.set(true, forKey: Self.didTerminateCleanlyKey)
    }
}
