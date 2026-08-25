import Foundation
import Observation

@Observable
@MainActor
final class PackageStore {
    struct Failure: Equatable {
        enum Kind: Equatable {
            case homebrewNotInstalled
            case commandFailed
            case commandTimedOut
            case connectivityFailure
            case unreadableOutdatedData
            case unreadablePackageMetadata
            case unexpected
        }

        let kind: Kind
        let message: String
        let commandResults: [CommandResult]
        let searchedExecutablePaths: [String]

        init(homebrewError: HomebrewError) {
            kind = Self.kind(for: homebrewError)
            message = homebrewError.localizedDescription
            commandResults = homebrewError.commandResults
            searchedExecutablePaths = switch homebrewError {
            case .notInstalled:
                HomebrewExecutableLocator.candidatePaths
            case .commandFailed,
                 .commandTimedOut,
                 .invalidOutdatedData,
                 .invalidPackageMetadata:
                []
            }
        }

        init(unexpectedError: any Error) {
            kind = .unexpected
            message = unexpectedError.localizedDescription
            commandResults = []
            searchedExecutablePaths = []
        }

        private static func kind(for error: HomebrewError) -> Kind {
            switch error {
            case .notInstalled:
                .homebrewNotInstalled
            case .commandFailed(let results):
                isLikelyConnectivityFailure(results.last?.standardError ?? "")
                    ? .connectivityFailure
                    : .commandFailed
            case .commandTimedOut:
                .commandTimedOut
            case .invalidOutdatedData:
                .unreadableOutdatedData
            case .invalidPackageMetadata:
                .unreadablePackageMetadata
            }
        }

        private static func isLikelyConnectivityFailure(_ standardError: String) -> Bool {
            let normalizedError = standardError.lowercased()
            return [
                "could not resolve host",
                "couldn't resolve host",
                "failed to connect",
                "could not connect",
                "couldn't connect",
                "network is unreachable",
                "network unavailable",
                "connection timed out",
                "operation timed out",
                "network connection was lost"
            ].contains { normalizedError.contains($0) }
        }
    }

    enum State: Equatable {
        case idle
        case loading
        case loaded(HomebrewInventoryReport)
        case refreshing(HomebrewInventoryReport)
        case failed(Failure, previousReport: HomebrewInventoryReport?)

        var isLoading: Bool {
            switch self {
            case .loading, .refreshing:
                true
            default:
                false
            }
        }

        var report: HomebrewInventoryReport? {
            switch self {
            case .loaded(let report), .refreshing(let report):
                report
            case .failed(_, let previousReport):
                previousReport
            case .idle, .loading:
                nil
            }
        }

        var availableUpdateCount: Int? {
            report?.inventory.availableUpdateCount
        }
    }

    private(set) var state: State
    private(set) var operationState: HomebrewPackageOperationState
    private(set) var operationFollowUpRefreshFailure: Failure?
    private let homebrewService: HomebrewService
    private let analytics: any AnalyticsTracking

    var confirmedOperationPlan: HomebrewPackageOperationPlan? {
        guard case .package(let plan) = operationState.confirmedPlan else {
            return nil
        }
        return plan
    }

    var confirmedUpdateAllPlan: HomebrewUpdateAllPlan? {
        guard case .updateAll(let plan) = operationState.confirmedPlan else {
            return nil
        }
        return plan
    }

    var isPerformingHomebrewWork: Bool {
        state.isLoading || operationState.isActive
    }

    var packageActionsDisabled: Bool {
        guard case .loaded = state else { return true }
        return isPerformingHomebrewWork
    }

    init(
        state: State = .idle,
        homebrewService: HomebrewService = HomebrewService(),
        analytics: any AnalyticsTracking = NoOpAnalyticsTracker.shared
    ) {
        self.state = state
        operationState = .idle
        operationFollowUpRefreshFailure = nil
        self.homebrewService = homebrewService
        self.analytics = analytics
    }

    func operationPlan(
        for packageID: HomebrewPackage.ID,
        kind: HomebrewPackageOperationKind
    ) throws -> HomebrewPackageOperationPlan {
        if let runningPlan = operationState.activePlan {
            throw HomebrewPackageOperationConfirmationError.operationInProgress(
                runningPlan.id
            )
        }

        guard case .loaded = state else {
            throw HomebrewPackageOperationConfirmationError.planChanged(packageID)
        }

        guard let package = state.report?.inventory.package(withID: packageID) else {
            throw HomebrewPackageOperationConfirmationError.planChanged(packageID)
        }

        return HomebrewPackageOperationPlan(
            kind: kind,
            package: package,
            command: try homebrewService.operationCommand(
                for: package,
                operation: kind
            )
        )
    }

    func updateAllOperationPlan() throws -> HomebrewOperationPlan {
        if let runningPlan = operationState.activePlan {
            throw HomebrewPackageOperationConfirmationError.operationInProgress(
                runningPlan.id
            )
        }

        guard case .loaded(let report) = state else {
            throw HomebrewPackageOperationConfirmationError.planChanged(
                HomebrewPackage.ID(kind: .formula, name: "__brewpulse_update_all__")
            )
        }

        let packages = report.inventory.actionableUpdates
        guard !packages.isEmpty else {
            throw HomebrewPackageOperationConfirmationError.planChanged(
                HomebrewPackage.ID(kind: .formula, name: "__brewpulse_update_all__")
            )
        }

        return .updateAll(
            HomebrewUpdateAllPlan(
                packages: packages,
                command: try homebrewService.updateAllCommand(for: packages)
            )
        )
    }

    func confirmOperation(_ plan: HomebrewPackageOperationPlan) throws {
        try confirmOperation(.package(plan))
    }

    func confirmOperation(_ plan: HomebrewOperationPlan) throws {
        let currentPlan: HomebrewOperationPlan
        switch plan {
        case .package(let packagePlan):
            currentPlan = .package(
                try operationPlan(
                    for: packagePlan.id,
                    kind: packagePlan.kind
                )
            )
        case .updateAll:
            currentPlan = try updateAllOperationPlan()
        }

        guard currentPlan == plan else {
            throw HomebrewPackageOperationConfirmationError.planChanged(plan.id)
        }

        operationState = .confirmed(plan)
        analytics.track(operationEvent(for: plan, outcome: nil))
    }

    func runConfirmedOperation() async {
        guard case .confirmed(let plan) = operationState else { return }

        operationFollowUpRefreshFailure = nil
        operationState = .running(plan)
        let homebrewService = homebrewService
        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try homebrewService.runOperation(plan)
            }.value
            if operationState.isCancelling {
                operationState = .cancelled(plan, result: result)
            } else {
                operationState = .completed(plan, result)
            }
        } catch let error as HomebrewError {
            let result = error.commandResults.last
            if operationState.isCancelling {
                operationState = .cancelled(plan, result: result)
            } else {
                operationState = .failed(
                    plan,
                    message: error.localizedDescription,
                    result: result
                )
            }
        } catch {
            if operationState.isCancelling {
                operationState = .cancelled(plan, result: nil)
            } else {
                operationState = .failed(
                    plan,
                    message: error.localizedDescription,
                    result: nil
                )
            }
        }

        let operationSucceeded = if case .completed = operationState {
            true
        } else {
            false
        }

        analytics.track(
            operationEvent(
                for: plan,
                outcome: operationAnalyticsOutcome
            )
        )

        await refresh(trigger: .operationFollowUp)
        if operationSucceeded,
           case .failed(let failure, previousReport: _) = state {
            operationFollowUpRefreshFailure = failure
        }
    }

    func cancelOperation() {
        guard case .running(let plan) = operationState else { return }

        operationState = .cancelling(plan)
        homebrewService.cancelCurrentCommand()
    }

    func recordMenuOpened() {
        analytics.track(.menuOpened)
    }

    func refresh(trigger: AnalyticsRefreshTrigger = .manual) async {
        guard !isPerformingHomebrewWork else { return }

        if case .confirmed = operationState {
            operationState = .idle
        }
        let previousReport = state.report
        state = previousReport.map(State.refreshing) ?? .loading
        do {
            let homebrewService = homebrewService
            let report = try await Task.detached(priority: .userInitiated) {
                try homebrewService.inventoryWithUpdateAvailability()
            }.value
            state = .loaded(report)
            operationFollowUpRefreshFailure = nil
            analytics.trackActivationIfNeeded()
            analytics.track(
                .refreshCompleted(trigger: trigger, outcome: .succeeded)
            )
        } catch let error as HomebrewError {
            let failure = Failure(homebrewError: error)
            state = .failed(
                failure,
                previousReport: previousReport
            )
            analytics.track(
                .refreshCompleted(
                    trigger: trigger,
                    outcome: .failed,
                    failureKind: failure.analyticsName
                )
            )
        } catch {
            let failure = Failure(unexpectedError: error)
            state = .failed(
                failure,
                previousReport: previousReport
            )
            analytics.track(
                .refreshCompleted(
                    trigger: trigger,
                    outcome: .failed,
                    failureKind: failure.analyticsName
                )
            )
        }
    }

    private var operationAnalyticsOutcome: AnalyticsOutcome {
        switch operationState {
        case .completed:
            .succeeded
        case .cancelled:
            .cancelled
        case .failed, .idle, .confirmed, .running, .cancelling:
            .failed
        }
    }

    private func operationEvent(
        for plan: HomebrewOperationPlan,
        outcome: AnalyticsOutcome?
    ) -> AnalyticsEvent {
        let kind = switch plan.kind {
        case .update:
            "update"
        case .uninstall:
            "uninstall"
        }
        let scope = plan.isUpdateAll ? "all" : "single"
        let packageKind = plan.package.map { package in
            switch package.kind {
            case .formula:
                "formula"
            case .cask:
                "cask"
            }
        }

        if let outcome {
            return .packageOperationCompleted(
                kind: kind,
                scope: scope,
                packageKind: packageKind,
                outcome: outcome
            )
        }
        return .packageOperationConfirmed(
            kind: kind,
            scope: scope,
            packageKind: packageKind
        )
    }
}

private extension PackageStore.Failure {
    var analyticsName: String {
        switch kind {
        case .homebrewNotInstalled:
            "homebrew_not_installed"
        case .commandFailed:
            "command_failed"
        case .commandTimedOut:
            "command_timed_out"
        case .connectivityFailure:
            "connectivity_failure"
        case .unreadableOutdatedData:
            "unreadable_outdated_data"
        case .unreadablePackageMetadata:
            "unreadable_package_metadata"
        case .unexpected:
            "unexpected"
        }
    }
}
