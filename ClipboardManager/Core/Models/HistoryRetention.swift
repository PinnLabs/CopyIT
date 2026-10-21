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
        case .forever: nil
        case .oneDay: Self.secondsPerDay
        case .sevenDays: 7 * Self.secondsPerDay
        case .thirtyDays: 30 * Self.secondsPerDay
        case .ninetyDays: 90 * Self.secondsPerDay
        }
    }
}
