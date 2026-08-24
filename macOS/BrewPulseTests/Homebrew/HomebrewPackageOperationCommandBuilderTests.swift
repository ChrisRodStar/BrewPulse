import Foundation
import Testing
@testable import BrewPulse

@Suite("Homebrew package operation command builder")
struct HomebrewPackageOperationCommandBuilderTests {
    private let brewURL = URL(fileURLWithPath: "/test/homebrew/bin/brew")
    private let builder = HomebrewPackageOperationCommandBuilder()

    @Test("Builds a formula upgrade from structured arguments")
    func buildsFormulaUpgrade() throws {
        let request = try builder.request(
            executableURL: brewURL,
            package: package(
                name: "custom/tools/libxml++@2.0",
                kind: .formula
            ),
            operation: .update
        )

        #expect(request == CommandRequest(
            executableURL: brewURL,
            arguments: [
                "upgrade",
                "--formula",
                "--",
                "custom/tools/libxml++@2.0"
            ]
        ))
    }

    @Test("Builds a cask upgrade from structured arguments")
    func buildsCaskUpgrade() throws {
        let request = try builder.request(
            executableURL: brewURL,
            package: package(
                name: "visual-studio-code",
                kind: .cask
            ),
            operation: .update
        )

        #expect(request == CommandRequest(
            executableURL: brewURL,
            arguments: [
                "upgrade",
                "--cask",
                "--",
                "visual-studio-code"
            ]
        ))
    }

    @Test("Builds Update All from exactly the reviewed packages")
    func buildsReviewedUpdateAll() throws {
        let packages = [
            package(name: "git", kind: .formula),
            package(name: "visual-studio-code", kind: .cask)
        ]

        let request = try builder.updateAllRequest(
            executableURL: brewURL,
            packages: packages
        )

        #expect(request == CommandRequest(
            executableURL: brewURL,
            arguments: ["upgrade", "--", "git", "visual-studio-code"]
        ))
    }

    @Test("Rejects unavailable upgrades and invalid package names")
    func rejectsUnsafeRequests() {
        let unavailablePackage = HomebrewPackage(
            name: "git",
            versions: HomebrewPackageVersions(installed: ["2.50.1"]),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )
        let invalidNamePackage = package(
            name: "git; open /Applications/Calculator.app",
            kind: .formula
        )

        #expect(throws: HomebrewPackageOperationCommandError.upgradeUnavailable(
            unavailablePackage.id
        )) {
            try builder.request(
                executableURL: brewURL,
                package: unavailablePackage,
                operation: .update
            )
        }
        #expect(throws: HomebrewPackageOperationCommandError.invalidPackageName(
            invalidNamePackage.name
        )) {
            try builder.request(
                executableURL: brewURL,
                package: invalidNamePackage,
                operation: .uninstall
            )
        }
    }

    @Test("Builds standard formula and cask uninstall commands")
    func buildsSafeUninstallCommands() throws {
        let formula = HomebrewPackage(
            name: "git",
            versions: HomebrewPackageVersions(installed: ["2.50.1"]),
            kind: .formula
        )
        let cask = HomebrewPackage(
            name: "grandperspective",
            versions: HomebrewPackageVersions(installed: ["3.7.2"]),
            kind: .cask
        )

        let formulaRequest = try builder.request(
            executableURL: brewURL,
            package: formula,
            operation: .uninstall
        )
        let caskRequest = try builder.request(
            executableURL: brewURL,
            package: cask,
            operation: .uninstall
        )

        #expect(formulaRequest.arguments == [
            "uninstall", "--formula", "--", "git"
        ])
        #expect(caskRequest.arguments == [
            "uninstall", "--cask", "--", "grandperspective"
        ])
        #expect(!formulaRequest.arguments.contains("--force"))
        #expect(!formulaRequest.arguments.contains("--ignore-dependencies"))
        #expect(!caskRequest.arguments.contains("--zap"))
    }

    private func package(
        name: String,
        kind: HomebrewPackage.Kind
    ) -> HomebrewPackage {
        HomebrewPackage(
            name: name,
            versions: HomebrewPackageVersions(
                installed: ["1.0"],
                available: "2.0"
            ),
            kind: kind,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )
    }
}
