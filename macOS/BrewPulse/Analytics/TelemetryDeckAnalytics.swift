import Foundation
import TelemetryDeck

@MainActor
final class TelemetryDeckAnalytics: AnalyticsTracking {
    private enum Key {
        static let firstObservedInstallation =
            "analytics.firstObservedInstallationReported"
        static let activationCompleted = "analytics.activationCompletedReported"
    }

    private let appID: String?
    private let userDefaults: UserDefaults
    private var isCollectionEnabled = false
    private var isInitialized = false
    private var hasTrackedLaunch = false

    var isConfigured: Bool {
        guard let appID else { return false }
        return !appID.isEmpty
    }

    init(
        bundle: Bundle = .main,
        userDefaults: UserDefaults = .standard
    ) {
        let configuredAppID = bundle.object(
            forInfoDictionaryKey: "BrewPulseTelemetryAppID"
        ) as? String
        appID = configuredAppID?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userDefaults = userDefaults
    }

    func start(isEnabled: Bool) {
        isCollectionEnabled = isEnabled
        guard isEnabled else { return }
        initializeIfNeeded()
        guard isInitialized else { return }

        if !userDefaults.bool(forKey: Key.firstObservedInstallation) {
            track(.installationFirstObserved)
            userDefaults.set(true, forKey: Key.firstObservedInstallation)
        }

        if !hasTrackedLaunch {
            hasTrackedLaunch = true
            track(.appLaunched)
        }
    }

    func setCollectionEnabled(_ isEnabled: Bool) {
        start(isEnabled: isEnabled)
    }

    func track(_ event: AnalyticsEvent) {
        guard isCollectionEnabled, isInitialized else { return }
        TelemetryDeck.signal(event.name, parameters: event.parameters)
    }

    func trackActivationIfNeeded() {
        guard isCollectionEnabled, isInitialized else { return }
        guard !userDefaults.bool(forKey: Key.activationCompleted) else { return }

        track(.activationCompleted)
        userDefaults.set(true, forKey: Key.activationCompleted)
    }

    private func initializeIfNeeded() {
        guard !isInitialized, let appID, !appID.isEmpty else { return }

        let configuration = TelemetryDeck.Config(appID: appID)
        configuration.defaultSignalPrefix = "BrewPulse."
        TelemetryDeck.initialize(config: configuration)
        isInitialized = true
    }
}
