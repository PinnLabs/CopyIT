import Foundation

enum HistoryRetention: String, CaseIterable {
    case forever
    case oneDay
    case sevenDays
    case thirtyDays
    case ninetyDays

    private static let secondsPerDay: TimeInterval = 24 * 60 * 60

    /// `nil` means items never expire.
    var maxAge: TimeInterval? {
        switch self {
        case .forever: return nil
        case .oneDay: return Self.secondsPerDay
        case .sevenDays: return 7 * Self.secondsPerDay
        case .thirtyDays: return 30 * Self.secondsPerDay
        case .ninetyDays: return 90 * Self.secondsPerDay
        }
    }
}
