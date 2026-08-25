import Foundation

@MainActor
protocol AnalyticsTracking: AnyObject {
    var isConfigured: Bool { get }

    func start(isEnabled: Bool)
    func setCollectionEnabled(_ isEnabled: Bool)
    func track(_ event: AnalyticsEvent)
    func trackActivationIfNeeded()
}

@MainActor
final class NoOpAnalyticsTracker: AnalyticsTracking {
    static let shared = NoOpAnalyticsTracker()

    let isConfigured = false

    private init() {}

    func start(isEnabled: Bool) {}
    func setCollectionEnabled(_ isEnabled: Bool) {}
    func track(_ event: AnalyticsEvent) {}
    func trackActivationIfNeeded() {}
}
