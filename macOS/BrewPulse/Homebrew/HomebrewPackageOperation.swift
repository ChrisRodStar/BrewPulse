import Foundation

nonisolated enum HomebrewPackageOperationKind: Equatable, Sendable {
    case update
    case uninstall
}

nonisolated enum HomebrewPackageOperationConfirmationError: LocalizedError, Equatable, Sendable {
    case planChanged(HomebrewPackage.ID)
    case operationInProgress(HomebrewPackage.ID)

    var errorDescription: String? {
        switch self {
        case .planChanged:
            "The package details changed. Review the latest Homebrew command and try again."
        case .operationInProgress:
            "Another Homebrew operation is already in progress."
        }
    }
}

nonisolated struct HomebrewPackageOperationPlan: Equatable, Identifiable, Sendable {
    let kind: HomebrewPackageOperationKind
    let package: HomebrewPackage
    let command: CommandRequest

    var id: HomebrewPackage.ID { package.id }
}

nonisolated struct HomebrewUpdateAllPlan: Equatable, Sendable {
    let packages: [HomebrewPackage]
    let command: CommandRequest
}

nonisolated enum HomebrewOperationPlan: Equatable, Identifiable, Sendable {
    case package(HomebrewPackageOperationPlan)
    case updateAll(HomebrewUpdateAllPlan)

    var id: HomebrewPackage.ID {
        switch self {
        case .package(let plan):
            plan.id
        case .updateAll:
            HomebrewPackage.ID(kind: .formula, name: "__brewpulse_update_all__")
        }
    }

    var kind: HomebrewPackageOperationKind {
        switch self {
        case .package(let plan):
            plan.kind
        case .updateAll:
            .update
        }
    }

    var package: HomebrewPackage? {
        guard case .package(let plan) = self else { return nil }
        return plan.package
    }

    var packages: [HomebrewPackage] {
        switch self {
        case .package(let plan):
            [plan.package]
        case .updateAll(let plan):
            plan.packages
        }
    }

    var command: CommandRequest {
        switch self {
        case .package(let plan):
            plan.command
        case .updateAll(let plan):
            plan.command
        }
    }

    var isUpdateAll: Bool {
        guard case .updateAll = self else { return false }
        return true
    }

    var displayName: String {
        switch self {
        case .package(let plan):
            plan.package.name
        case .updateAll(let plan):
            "All \(plan.packages.count) updates"
        }
    }
}
