nonisolated enum HomebrewPackageOperationState: Equatable, Sendable {
    case idle
    case confirmed(HomebrewPackageOperationPlan)
    case running(HomebrewPackageOperationPlan)
    case cancelling(HomebrewPackageOperationPlan)
    case completed(HomebrewPackageOperationPlan, CommandResult)
    case failed(
        HomebrewPackageOperationPlan,
        message: String,
        result: CommandResult?
    )
    case cancelled(HomebrewPackageOperationPlan, result: CommandResult?)

    var confirmedPlan: HomebrewPackageOperationPlan? {
        guard case .confirmed(let plan) = self else { return nil }
        return plan
    }

    var runningPlan: HomebrewPackageOperationPlan? {
        guard case .running(let plan) = self else { return nil }
        return plan
    }

    var activePlan: HomebrewPackageOperationPlan? {
        switch self {
        case .running(let plan), .cancelling(let plan):
            plan
        case .idle, .confirmed, .completed, .failed, .cancelled:
            nil
        }
    }

    var isCancelling: Bool {
        guard case .cancelling = self else { return false }
        return true
    }

    var isActive: Bool {
        activePlan != nil
    }

    var terminalOutput: HomebrewPackageOperationOutput? {
        switch self {
        case .completed(let plan, let result):
            HomebrewPackageOperationOutput(
                plan: plan,
                status: .succeeded,
                result: result
            )
        case .failed(let plan, let message, let result):
            HomebrewPackageOperationOutput(
                plan: plan,
                status: .failed(message: message),
                result: result
            )
        case .cancelled(let plan, let result):
            HomebrewPackageOperationOutput(
                plan: plan,
                status: .cancelled,
                result: result
            )
        case .idle, .confirmed, .running, .cancelling:
            nil
        }
    }
}
