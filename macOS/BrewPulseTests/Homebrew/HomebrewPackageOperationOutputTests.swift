import Foundation
import Testing
@testable import BrewPulse

@Suite("Homebrew package operation output")
struct HomebrewPackageOperationOutputTests {
    @Test("Exposes output only after an update completes")
    func exposesCompletedOutput() throws {
        let package = HomebrewPackage(
            name: "git",
            versions: HomebrewPackageVersions(
                installed: ["2.49.0"],
                available: "2.50.1"
            ),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/test/homebrew/bin/brew"),
            arguments: ["upgrade", "--formula", "--", package.name]
        )
        let plan = HomebrewPackageOperationPlan(
            kind: .update,
            package: package,
            command: request
        )
        let result = CommandResult.testResult(
            for: request,
            standardOutput: "updated git\n",
            standardError: "warning\n"
        )

        #expect(HomebrewPackageOperationState.idle.terminalOutput == nil)
        #expect(HomebrewPackageOperationState.running(plan).terminalOutput == nil)

        let output = try #require(
            HomebrewPackageOperationState.completed(plan, result).terminalOutput
        )
        #expect(output.id == package.id)
        #expect(output.plan == plan)
        #expect(output.status == .succeeded)
        #expect(output.result == result)
        #expect(output.result?.standardOutput == "updated git\n")
        #expect(output.result?.standardError == "warning\n")
    }

    @Test("Copies a single output stream without rewriting it")
    func preservesSingleStreamForCopying() {
        let standardOutput = "updated git\nwith exact spacing  \n"
        let standardError = "warning from Homebrew\n"

        #expect(
            makeOutput(standardOutput: standardOutput).textForCopying
                == standardOutput
        )
        #expect(
            makeOutput(standardError: standardError).textForCopying
                == standardError
        )
    }

    @Test("Labels stdout and stderr when copying both streams")
    func labelsBothStreamsForCopying() {
        let output = makeOutput(
            standardOutput: "updated git\n",
            standardError: "warning from Homebrew\n"
        )

        #expect(output.textForCopying == """
        Standard Output:
        updated git

        Standard Error:
        warning from Homebrew

        """)
    }

    @Test("Produces no copy text when Homebrew produced no output")
    func hasNoCopyTextForEmptyOutput() {
        #expect(makeOutput().textForCopying.isEmpty)
    }

    private func makeOutput(
        standardOutput: String = "",
        standardError: String = ""
    ) -> HomebrewPackageOperationOutput {
        let package = HomebrewPackage(
            name: "git",
            versions: HomebrewPackageVersions(
                installed: ["2.49.0"],
                available: "2.50.1"
            ),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/test/homebrew/bin/brew"),
            arguments: ["upgrade", "--formula", "--", package.name]
        )
        return HomebrewPackageOperationOutput(
            plan: HomebrewPackageOperationPlan(
                kind: .update,
                package: package,
                command: request
            ),
            status: .succeeded,
            result: .testResult(
                for: request,
                standardOutput: standardOutput,
                standardError: standardError
            )
        )
    }
}
