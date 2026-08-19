import AppKit
import Observation

protocol ApplicationPresentationServing {
    func setDockIconVisible(_ isVisible: Bool)
    func activate()
}

struct SystemApplicationPresentationService: ApplicationPresentationServing {
    func setDockIconVisible(_ isVisible: Bool) {
        NSApplication.shared.setActivationPolicy(
            isVisible ? .regular : .accessory
        )
    }

    func activate() {
        NSApplication.shared.activate()
    }
}

@Observable
@MainActor
final class ApplicationPresentationController {
    private let service: any ApplicationPresentationServing

    init(
        service: any ApplicationPresentationServing =
            SystemApplicationPresentationService()
    ) {
        self.service = service
    }

    func showSettingsPresence() {
        service.setDockIconVisible(true)
    }

    func activate() {
        service.activate()
    }

    func hideSettingsPresence() {
        service.setDockIconVisible(false)
    }
}
