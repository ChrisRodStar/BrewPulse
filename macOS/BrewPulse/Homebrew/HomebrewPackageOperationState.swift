nonisolated enum HomebrewPackageOperationState: Equatable, Sendable {
    case idle
    case confirmed(HomebrewOperationPlan)
    case running(HomebrewOperationPlan)
    case cancelling(HomebrewOperationPlan)
    case completed(HomebrewOperationPlan, CommandResult)
    case failed(
        HomebrewOperationPlan,
        message: String,
        result: CommandResult?
    )
    case cancelled(HomebrewOperationPlan, result: CommandResult?)

    var confirmedPlan: HomebrewOperationPlan? {
        guard case .confirmed(let plan) = self else { return nil }
        return plan
    }

    var runningPlan: HomebrewOperationPlan? {
        guard case .running(let plan) = self else { return nil }
        return plan
    }

    var activePlan: HomebrewOperationPlan? {
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
