import ServiceManagement

nonisolated enum LaunchAtLoginStatus: Equatable, Sendable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

protocol LaunchAtLoginServing {
    func status() -> LaunchAtLoginStatus
    func setEnabled(_ isEnabled: Bool) throws
    func openSystemSettings()
}

struct SystemLaunchAtLoginService: LaunchAtLoginServing {
    func status() -> LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .notRegistered:
            .disabled
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable
        @unknown default:
            .unavailable
        }
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
