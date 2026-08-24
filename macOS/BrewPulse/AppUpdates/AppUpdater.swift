import Combine
import Sparkle

@MainActor
final class AppUpdater: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    @Published private(set) var canCheckForUpdates = false

    init(startingUpdater: Bool = true) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: startingUpdater,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)

        if startingUpdater && updaterController.updater.automaticallyChecksForUpdates {
            updaterController.updater.checkForUpdatesInBackground()
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
