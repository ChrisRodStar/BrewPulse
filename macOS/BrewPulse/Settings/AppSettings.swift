import Observation
import Foundation

@Observable
@MainActor
final class AppSettings {
    static let analyticsEnabledKey = "analytics.isEnabled"

    private let launchAtLoginService: any LaunchAtLoginServing
    private let analytics: any AnalyticsTracking
    private let userDefaults: UserDefaults

    private(set) var launchAtLoginStatus: LaunchAtLoginStatus
    private(set) var launchAtLoginErrorMessage: String?
    private(set) var sharesAnonymousUsageStatistics: Bool

    var isAnalyticsAvailable: Bool {
        analytics.isConfigured
    }

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
            SystemLaunchAtLoginService(),
        analytics: any AnalyticsTracking = NoOpAnalyticsTracker.shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.launchAtLoginService = launchAtLoginService
        self.analytics = analytics
        self.userDefaults = userDefaults
        launchAtLoginStatus = launchAtLoginService.status()
        sharesAnonymousUsageStatistics = analytics.isConfigured
            && (userDefaults.object(forKey: Self.analyticsEnabledKey) as? Bool ?? true)
        analytics.start(isEnabled: sharesAnonymousUsageStatistics)
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

    func setSharesAnonymousUsageStatistics(_ isEnabled: Bool) {
        let enabled = analytics.isConfigured && isEnabled
        sharesAnonymousUsageStatistics = enabled
        userDefaults.set(enabled, forKey: Self.analyticsEnabledKey)
        analytics.setCollectionEnabled(enabled)
    }
}
