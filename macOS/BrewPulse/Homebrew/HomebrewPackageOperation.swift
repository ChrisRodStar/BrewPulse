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
