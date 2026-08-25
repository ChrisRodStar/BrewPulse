import SwiftUI

@main
struct BrewPulseApp: App {
    @StateObject private var updater = AppUpdater()
    @State private var store: PackageStore
    @State private var settings: AppSettings
    @State private var presentation = ApplicationPresentationController()
    @State private var operationReviewPresentation = PackageOperationReviewPresentation()

    init() {
        let analytics = BrewPulseAnalytics()
        _store = State(initialValue: PackageStore(analytics: analytics))
        _settings = State(initialValue: AppSettings(analytics: analytics))
    }

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environment(store)
                .environment(presentation)
                .environment(operationReviewPresentation)
        } label: {
            BrewPulseMenuBarLabel(updateCount: store.state.availableUpdateCount)
        }
        .menuBarExtraStyle(.window)

        packageOperationReviewWindow

        Settings {
            BrewPulseSettingsView()
                .environment(settings)
                .environment(presentation)
                .environmentObject(updater)
        }
    }

    private var packageOperationReviewWindow: some Scene {
        Window(
            "Review Package Action",
            id: PackageOperationReviewPresentation.windowID
        ) {
            PackageOperationReviewWindow()
                .environment(store)
                .environment(operationReviewPresentation)
        }
        .defaultPosition(.center)
        .defaultSize(width: 560, height: 320)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
