import Foundation

nonisolated struct AnalyticsEvent: Equatable, Sendable {
    let name: String
    let parameters: [String: String]

    static let appLaunched = AnalyticsEvent(
        name: "App.launched",
        parameters: [:]
    )

    static let installationFirstObserved = AnalyticsEvent(
        name: "Installation.firstObserved",
        parameters: [:]
    )

    static let activationCompleted = AnalyticsEvent(
        name: "Activation.completed",
        parameters: [:]
    )

    static let menuOpened = AnalyticsEvent(
        name: "Engagement.menuOpened",
        parameters: [:]
    )

    static func refreshCompleted(
        trigger: AnalyticsRefreshTrigger,
        outcome: AnalyticsOutcome,
        failureKind: String? = nil
    ) -> AnalyticsEvent {
        var parameters = [
            "trigger": trigger.rawValue,
            "outcome": outcome.rawValue
        ]
        if let failureKind {
            parameters["failure_kind"] = failureKind
        }
        return AnalyticsEvent(
            name: "HomebrewRefresh.completed",
            parameters: parameters
        )
    }

    static func packageOperationConfirmed(
        kind: String,
        scope: String,
        packageKind: String?
    ) -> AnalyticsEvent {
        packageOperationEvent(
            name: "PackageOperation.confirmed",
            kind: kind,
            scope: scope,
            packageKind: packageKind,
            outcome: nil
        )
    }

    static func packageOperationCompleted(
        kind: String,
        scope: String,
        packageKind: String?,
        outcome: AnalyticsOutcome
    ) -> AnalyticsEvent {
        packageOperationEvent(
            name: "PackageOperation.completed",
            kind: kind,
            scope: scope,
            packageKind: packageKind,
            outcome: outcome
        )
    }

    private static func packageOperationEvent(
        name: String,
        kind: String,
        scope: String,
        packageKind: String?,
        outcome: AnalyticsOutcome?
    ) -> AnalyticsEvent {
        var parameters = [
            "operation_kind": kind,
            "scope": scope
        ]
        if let packageKind {
            parameters["package_kind"] = packageKind
        }
        if let outcome {
            parameters["outcome"] = outcome.rawValue
        }
        return AnalyticsEvent(name: name, parameters: parameters)
    }
}

nonisolated enum AnalyticsRefreshTrigger: String, Equatable, Sendable {
    case appOpen = "app_open"
    case manual
    case operationFollowUp = "operation_follow_up"
}

nonisolated enum AnalyticsOutcome: String, Equatable, Sendable {
    case succeeded
    case failed
    case cancelled
}
