import Foundation

nonisolated enum HomebrewPackageOperationCommandError: LocalizedError, Equatable, Sendable {
    case invalidPackageName(String)
    case upgradeUnavailable(HomebrewPackage.ID)

    var errorDescription: String? {
        switch self {
        case .invalidPackageName:
            "The package name returned by Homebrew is not valid. Refresh and try again."
        case .upgradeUnavailable:
            "This package is not currently eligible for a standard Homebrew upgrade."
        }
    }
}

nonisolated struct HomebrewPackageOperationCommandBuilder: Sendable {
    func request(
        executableURL: URL,
        package: HomebrewPackage,
        operation: HomebrewPackageOperationKind
    ) throws -> CommandRequest {
        if operation == .update, !package.isStandardUpgradeAvailable {
            throw HomebrewPackageOperationCommandError.upgradeUnavailable(
                package.id
            )
        }
        guard Self.isValidPackageName(package.name) else {
            throw HomebrewPackageOperationCommandError.invalidPackageName(
                package.name
            )
        }

        let operationArgument = switch operation {
        case .update:
            "upgrade"
        case .uninstall:
            "uninstall"
        }
        let kindArgument = switch package.kind {
        case .formula:
            "--formula"
        case .cask:
            "--cask"
        }

        return CommandRequest(
            executableURL: executableURL,
            arguments: [operationArgument, kindArgument, "--", package.name]
        )
    }

    private static func isValidPackageName(_ name: String) -> Bool {
        let components = name.split(
            separator: "/",
            omittingEmptySubsequences: false
        )
        guard components.count == 1 || components.count == 3 else {
            return false
        }

        return components.allSatisfy { component in
            !component.isEmpty
                && component.unicodeScalars.allSatisfy(isAllowedNameScalar)
                && component.unicodeScalars.contains(where: isASCIIAlphanumeric)
        }
    }

    private static func isAllowedNameScalar(_ scalar: Unicode.Scalar) -> Bool {
        if isASCIIAlphanumeric(scalar) {
            return true
        }

        return switch scalar.value {
        case 43, 45, 46, 64, 95: // + - . @ _
            true
        default:
            false
        }
    }

    private static func isASCIIAlphanumeric(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 48...57, 65...90, 97...122:
            true
        default:
            false
        }
    }
}
