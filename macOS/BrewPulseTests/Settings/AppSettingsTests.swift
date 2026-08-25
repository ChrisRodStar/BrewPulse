import Foundation
import Testing
@testable import BrewPulse

@Suite("App settings")
@MainActor
struct AppSettingsTests {
    @Test("Reflects the current launch at login status")
    func reflectsCurrentStatus() {
        let service = StubLaunchAtLoginService(status: .requiresApproval)
        let settings = AppSettings(launchAtLoginService: service)

        #expect(settings.launchesAtLogin)
        #expect(settings.launchAtLoginStatus == .requiresApproval)
    }

    @Test("Enables and disables launch at login")
    func changesLaunchAtLogin() {
        let service = StubLaunchAtLoginService(status: .disabled)
        let settings = AppSettings(launchAtLoginService: service)

        settings.launchesAtLogin = true
        settings.launchesAtLogin = false

        #expect(service.requests == [true, false])
        #expect(settings.launchAtLoginStatus == .disabled)
        #expect(!settings.launchesAtLogin)
    }

    @Test("Dismisses launch at login errors through presentation state")
    func dismissesRegistrationError() {
        let expectedError = NSError(
            domain: "AppSettingsTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Registration was denied."]
        )
        let settings = AppSettings(
            launchAtLoginService: StubLaunchAtLoginService(
                status: .disabled,
                error: expectedError
            )
        )

        settings.launchesAtLogin = true
        #expect(settings.isShowingLaunchAtLoginError)

        settings.isShowingLaunchAtLoginError = false

        #expect(!settings.isShowingLaunchAtLoginError)
        #expect(settings.launchAtLoginErrorMessage == nil)
    }

    @Test("Keeps the system status and exposes registration failures")
    func reportsRegistrationFailure() {
        let expectedError = NSError(
            domain: "AppSettingsTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Registration was denied."]
        )
        let service = StubLaunchAtLoginService(
            status: .disabled,
            error: expectedError
        )
        let settings = AppSettings(launchAtLoginService: service)

        settings.launchesAtLogin = true

        #expect(settings.launchAtLoginStatus == .disabled)
        #expect(!settings.launchesAtLogin)
        #expect(settings.launchAtLoginErrorMessage == "Registration was denied.")
    }

    @Test("Refreshes changes made in System Settings")
    func refreshesExternalChanges() {
        let service = StubLaunchAtLoginService(status: .disabled)
        let settings = AppSettings(launchAtLoginService: service)
        service.currentStatus = .enabled

        settings.refreshLaunchAtLoginStatus()

        #expect(settings.launchAtLoginStatus == .enabled)
        #expect(settings.launchesAtLogin)
    }

    @Test("Enables anonymous analytics by default and persists opt-out")
    func managesAnalyticsPreference() throws {
        let suiteName = "AppSettingsTests.analytics.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let analytics = StubAnalyticsTracker()
        let settings = AppSettings(
            launchAtLoginService: StubLaunchAtLoginService(status: .disabled),
            analytics: analytics,
            userDefaults: defaults
        )

        #expect(settings.sharesAnonymousUsageStatistics)
        #expect(settings.isAnalyticsAvailable)
        #expect(analytics.startRequests == [true])

        settings.setSharesAnonymousUsageStatistics(false)

        #expect(!settings.sharesAnonymousUsageStatistics)
        #expect(defaults.object(forKey: AppSettings.analyticsEnabledKey) as? Bool == false)
        #expect(analytics.collectionRequests == [false])
    }

    @Test("Keeps analytics disabled when the build is not configured")
    func disablesUnconfiguredAnalytics() throws {
        let suiteName = "AppSettingsTests.unconfiguredAnalytics.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let analytics = StubAnalyticsTracker(isConfigured: false)
        let settings = AppSettings(
            launchAtLoginService: StubLaunchAtLoginService(status: .disabled),
            analytics: analytics,
            userDefaults: defaults
        )

        #expect(!settings.isAnalyticsAvailable)
        #expect(!settings.sharesAnonymousUsageStatistics)
        #expect(analytics.startRequests == [false])

        settings.setSharesAnonymousUsageStatistics(true)

        #expect(!settings.sharesAnonymousUsageStatistics)
        #expect(analytics.collectionRequests == [false])
    }
}

@MainActor
private final class StubAnalyticsTracker: AnalyticsTracking {
    let isConfigured: Bool
    private(set) var startRequests: [Bool] = []
    private(set) var collectionRequests: [Bool] = []

    init(isConfigured: Bool = true) {
        self.isConfigured = isConfigured
    }

    func start(isEnabled: Bool) {
        startRequests.append(isEnabled)
    }

    func setCollectionEnabled(_ isEnabled: Bool) {
        collectionRequests.append(isEnabled)
    }

    func track(_ event: AnalyticsEvent) {}
    func trackActivationIfNeeded() {}
}

@MainActor
private final class StubLaunchAtLoginService: LaunchAtLoginServing {
    var currentStatus: LaunchAtLoginStatus
    private let error: Error?
    private(set) var requests: [Bool] = []

    init(
        status: LaunchAtLoginStatus,
        error: Error? = nil
    ) {
        currentStatus = status
        self.error = error
    }

    func status() -> LaunchAtLoginStatus {
        currentStatus
    }

    func setEnabled(_ isEnabled: Bool) throws {
        requests.append(isEnabled)
        if let error {
            throw error
        }
        currentStatus = isEnabled ? .enabled : .disabled
    }

    func openSystemSettings() {}
}
