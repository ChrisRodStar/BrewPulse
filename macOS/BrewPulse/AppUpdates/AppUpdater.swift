import Combine
import Sparkle

@MainActor
final class AppUpdater: NSObject, ObservableObject, SPUStandardUserDriverDelegate {
    private let startingUpdater: Bool
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: startingUpdater,
        updaterDelegate: nil,
        userDriverDelegate: self
    )

    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var hasPendingScheduledUpdate = false

    init(startingUpdater: Bool = true) {
        self.startingUpdater = startingUpdater
        super.init()

        updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)

        if startingUpdater && updaterController.updater.automaticallyChecksForUpdates {
            updaterController.updater.checkForUpdatesInBackground()
        }
    }

    func checkForUpdates() {
        hasPendingScheduledUpdate = false
        updaterController.checkForUpdates(nil)
    }

    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        immediateFocus
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        if !handleShowingUpdate {
            hasPendingScheduledUpdate = true
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        hasPendingScheduledUpdate = false
    }

    func standardUserDriverWillFinishUpdateSession() {
        hasPendingScheduledUpdate = false
    }
}
