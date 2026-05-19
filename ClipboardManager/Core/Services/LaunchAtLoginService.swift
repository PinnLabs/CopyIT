import Foundation
import ServiceManagement

final class LaunchAtLoginService: LaunchAtLoginManaging {
    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
    }

    var isEnabled: Bool {
        service.status == .enabled
    }

    func enable() throws {
        guard service.status != .enabled else { return }
        try service.register()
    }

    func disable() throws {
        guard service.status != .notRegistered else { return }
        try service.unregister()
    }
}
