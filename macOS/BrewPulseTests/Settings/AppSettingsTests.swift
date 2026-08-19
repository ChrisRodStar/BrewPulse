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

        settings.setLaunchesAtLogin(true)
        settings.setLaunchesAtLogin(false)

        #expect(service.requests == [true, false])
        #expect(settings.launchAtLoginStatus == .disabled)
        #expect(!settings.launchesAtLogin)
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

        settings.setLaunchesAtLogin(true)

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
