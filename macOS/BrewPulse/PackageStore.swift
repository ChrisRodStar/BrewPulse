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

    var confirmedOperationPlan: HomebrewPackageOperationPlan? {
        operationState.confirmedPlan
    }

    var isPerformingHomebrewWork: Bool {
        state.isLoading || operationState.isActive
    }

    init(
        state: State = .idle,
        homebrewService: HomebrewService = HomebrewService()
    ) {
        self.state = state
        operationState = .idle
        operationFollowUpRefreshFailure = nil
        self.homebrewService = homebrewService
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

    func confirmOperation(_ plan: HomebrewPackageOperationPlan) throws {
        let currentPlan = try operationPlan(for: plan.id, kind: plan.kind)
        guard currentPlan == plan else {
            throw HomebrewPackageOperationConfirmationError.planChanged(plan.id)
        }

        operationState = .confirmed(plan)
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

        await refresh()
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

    func refresh() async {
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
        } catch let error as HomebrewError {
            state = .failed(
                Failure(homebrewError: error),
                previousReport: previousReport
            )
        } catch {
            state = .failed(
                Failure(unexpectedError: error),
                previousReport: previousReport
            )
        }
    }
}
