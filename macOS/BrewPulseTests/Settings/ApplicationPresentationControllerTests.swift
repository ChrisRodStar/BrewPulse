import Testing
@testable import BrewPulse

@Suite("Application presentation")
@MainActor
struct ApplicationPresentationControllerTests {
    @Test("Settings presence shows and hides the Dock icon")
    func changesDockIconVisibility() {
        let service = ApplicationPresentationServiceStub()
        let controller = ApplicationPresentationController(service: service)

        controller.showSettingsPresence()
        controller.hideSettingsPresence()

        #expect(service.dockVisibilityChanges == [true, false])
    }

    @Test("Settings can bring the application to the front")
    func activatesApplication() {
        let service = ApplicationPresentationServiceStub()
        let controller = ApplicationPresentationController(service: service)

        controller.activate()

        #expect(service.activationCount == 1)
    }
}

private final class ApplicationPresentationServiceStub:
    ApplicationPresentationServing
{
    private(set) var dockVisibilityChanges: [Bool] = []
    private(set) var activationCount = 0

    func setDockIconVisible(_ isVisible: Bool) {
        dockVisibilityChanges.append(isVisible)
    }

    func activate() {
        activationCount += 1
    }
}
