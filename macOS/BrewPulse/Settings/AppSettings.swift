import Observation

@Observable
@MainActor
final class AppSettings {
    private let launchAtLoginService: any LaunchAtLoginServing

    private(set) var launchAtLoginStatus: LaunchAtLoginStatus
    private(set) var launchAtLoginErrorMessage: String?

    var launchesAtLogin: Bool {
        get {
            switch launchAtLoginStatus {
            case .enabled, .requiresApproval:
                true
            case .disabled, .unavailable:
                false
            }
        }
        set { setLaunchesAtLogin(newValue) }
    }

    var isShowingLaunchAtLoginError: Bool {
        get { launchAtLoginErrorMessage != nil }
        set {
            if !newValue {
                launchAtLoginErrorMessage = nil
            }
        }
    }

    init(
        launchAtLoginService: any LaunchAtLoginServing =
            SystemLaunchAtLoginService()
    ) {
        self.launchAtLoginService = launchAtLoginService
        launchAtLoginStatus = launchAtLoginService.status()
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = launchAtLoginService.status()
    }

    private func setLaunchesAtLogin(_ isEnabled: Bool) {
        launchAtLoginErrorMessage = nil

        do {
            try launchAtLoginService.setEnabled(isEnabled)
        } catch {
            launchAtLoginErrorMessage = error.localizedDescription
        }

        refreshLaunchAtLoginStatus()
    }

    func openLoginItemSettings() {
        launchAtLoginService.openSystemSettings()
    }
}
