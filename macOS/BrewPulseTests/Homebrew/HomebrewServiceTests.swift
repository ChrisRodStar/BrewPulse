import Foundation
import Testing
@testable import BrewPulse

@Suite("Homebrew service")
struct HomebrewServiceTests {
    private let brewURL = URL(fileURLWithPath: "/test/homebrew/bin/brew")

    @Test("Builds list commands and assembles inventory")
    func buildsInstalledInventory() throws {
        let refreshedAt = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let casksOutput = try FixtureLoader.text(named: "casks")
        let formulaeOutput = try FixtureLoader.text(named: "formulae")
        let runner = RecordingCommandRunner { request in
            let output = switch request.arguments {
            case ["list", "--cask", "--versions"]:
                casksOutput
            case ["list", "--formula", "--versions"]:
                formulaeOutput
            case ["--version"]:
                "Homebrew 5.0.0\n"
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }

            return .testResult(for: request, standardOutput: output)
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL,
            currentDate: { refreshedAt }
        )

        let report = try service.installedInventory()
        let inventory = report.inventory

        #expect(runner.requests == [
            CommandRequest(
                executableURL: brewURL,
                arguments: ["list", "--cask", "--versions"]
            ),
            CommandRequest(
                executableURL: brewURL,
                arguments: ["list", "--formula", "--versions"]
            ),
            CommandRequest(
                executableURL: brewURL,
                arguments: ["--version"]
            )
        ])
        #expect(inventory.applications.map(\.name) == [
            "1password",
            "font-fira-code",
            "visual-studio-code"
        ])
        #expect(inventory.formulae.map(\.name) == [
            "git",
            "local-tool",
            "openssl@3",
            "python@3.13",
            "zlib"
        ])
        #expect(inventory.count == 8)
        #expect(report.homebrewVersion == "5.0.0")
        #expect(report.commandResults.map(\.standardOutput) == [
            casksOutput,
            formulaeOutput,
            "Homebrew 5.0.0\n"
        ])
        #expect(report.refreshedAt == refreshedAt)
    }

    @Test("Builds an update command without executing it")
    func buildsUpdateCommandWithoutExecution() throws {
        let runner = RecordingCommandRunner { request in
            throw RecordingCommandRunnerError.unexpectedRequest(request)
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )
        let package = HomebrewPackage(
            name: "git",
            versions: HomebrewPackageVersions(
                installed: ["2.49.0"],
                available: "2.50.1"
            ),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )

        let request = try service.operationCommand(
            for: package,
            operation: .update
        )

        #expect(request == CommandRequest(
            executableURL: brewURL,
            arguments: ["upgrade", "--formula", "--", "git"]
        ))
        #expect(runner.requests.isEmpty)
    }

    @Test("Runs the exact confirmed update command and preserves its output")
    func runsConfirmedUpdateCommand() throws {
        let command = CommandRequest(
            executableURL: brewURL,
            arguments: ["upgrade", "--formula", "--", "git"]
        )
        let expectedResult = CommandResult.testResult(
            for: command,
            standardOutput: "updating git\n",
            standardError: "warning\n"
        )
        let runner = RecordingCommandRunner { request in
            expectedResult
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )
        let plan = HomebrewPackageOperationPlan(
            kind: .update,
            package: HomebrewPackage(
                name: "git",
                versions: HomebrewPackageVersions(
                    installed: ["2.49.0"],
                    available: "2.50.1"
                ),
                kind: .formula,
                upgradeEligibility: HomebrewPackageUpgradeEligibility()
            ),
            command: command
        )

        let result = try service.runOperation(plan)

        #expect(runner.requests == [command])
        #expect(result == expectedResult)
    }

    @Test("Treats a nonzero update exit as a failure without losing output")
    func rejectsFailedUpdateCommand() {
        let command = CommandRequest(
            executableURL: brewURL,
            arguments: ["upgrade", "--formula", "--", "git"]
        )
        let failedResult = CommandResult.testResult(
            for: command,
            standardOutput: "partial update\n",
            standardError: "permission denied\n",
            terminationStatus: 1
        )
        let runner = RecordingCommandRunner { _ in failedResult }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )
        let plan = HomebrewPackageOperationPlan(
            kind: .update,
            package: HomebrewPackage(
                name: "git",
                versions: HomebrewPackageVersions(
                    installed: ["2.49.0"],
                    available: "2.50.1"
                ),
                kind: .formula,
                upgradeEligibility: HomebrewPackageUpgradeEligibility()
            ),
            command: command
        )

        do {
            _ = try service.runOperation(plan)
            Issue.record("Expected the update command to fail")
        } catch HomebrewError.commandFailed(let results) {
            #expect(results == [failedResult])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Forwards cancellation to the command runner")
    func forwardsCancellation() {
        let runner = RecordingCommandRunner { request in
            .testResult(for: request)
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        service.cancelCurrentCommand()

        #expect(runner.cancellationRequested)
    }

    @Test("Preserves original output while presenting a concise command failure")
    func preservesCommandFailureOutput() {
        let runner = RecordingCommandRunner { request in
            .testResult(
                for: request,
                standardOutput: "partial output\n\n",
                standardError: "  permission denied\n",
                terminationStatus: 1
            )
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        do {
            _ = try service.installedInventory()
            Issue.record("Expected the Homebrew command to fail")
        } catch let error as HomebrewError {
            #expect(error.localizedDescription == "permission denied")
            #expect(error.commandResults.map(\.standardOutput) == ["partial output\n\n"])
            #expect(error.commandResults.map(\.standardError) == ["  permission denied\n"])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(runner.requests == [
            CommandRequest(
                executableURL: brewURL,
                arguments: ["list", "--cask", "--versions"]
            )
        ])
    }

    @Test("Preserves earlier command output when a later command fails")
    func preservesOutputBeforeLaterFailure() {
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["list", "--cask", "--versions"]:
                return .testResult(
                    for: request,
                    standardOutput: "example-app 1.0\n",
                    standardError: "cask warning\n"
                )
            case ["list", "--formula", "--versions"]:
                return .testResult(
                    for: request,
                    standardOutput: "partial formula output\n",
                    standardError: "formula failure\n",
                    terminationStatus: 2
                )
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        do {
            _ = try service.installedInventory()
            Issue.record("Expected the formula command to fail")
        } catch let error as HomebrewError {
            #expect(error.commandResults.map(\.standardOutput) == [
                "example-app 1.0\n",
                "partial formula output\n"
            ])
            #expect(error.commandResults.map(\.standardError) == [
                "cask warning\n",
                "formula failure\n"
            ])
            #expect(error.commandResults.map(\.terminationStatus) == [0, 2])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Preserves package output when the version command fails")
    func preservesOutputBeforeVersionFailure() {
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["list", "--cask", "--versions"]:
                return .testResult(
                    for: request,
                    standardOutput: "example-app 1.0\n"
                )
            case ["list", "--formula", "--versions"]:
                return .testResult(
                    for: request,
                    standardOutput: "example-tool 2.0\n"
                )
            case ["--version"]:
                return .testResult(
                    for: request,
                    standardOutput: "partial version output\n",
                    standardError: "version lookup failed\n",
                    terminationStatus: 2
                )
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        do {
            _ = try service.installedInventory()
            Issue.record("Expected the version command to fail")
        } catch HomebrewError.commandFailed(let results) {
            #expect(results.map(\.standardOutput) == [
                "example-app 1.0\n",
                "example-tool 2.0\n",
                "partial version output\n"
            ])
            #expect(results.last?.standardError == "version lookup failed\n")
            #expect(results.last?.terminationStatus == 2)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Builds structured outdated and installed-metadata commands")
    func buildsOutdatedDataCommand() throws {
        let outdatedOutput = try FixtureLoader.text(
            named: "outdated",
            fileExtension: "json"
        )
        let metadataOutput = try FixtureLoader.text(
            named: "installed-metadata",
            fileExtension: "json"
        )
        let runner = RecordingCommandRunner { request in
            let output = switch request.arguments {
            case ["outdated", "--json=v2"]:
                outdatedOutput
            case ["info", "--json=v2", "--installed"]:
                metadataOutput
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }

            return .testResult(for: request, standardOutput: output)
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        let report = try service.outdatedData()

        #expect(runner.requests == [
            CommandRequest(
                executableURL: brewURL,
                arguments: ["outdated", "--json=v2"]
            ),
            CommandRequest(
                executableURL: brewURL,
                arguments: ["info", "--json=v2", "--installed"]
            )
        ])
        #expect(report.outdatedData.packages.map(\.name) == [
            "git",
            "custom/tools/widget",
            "visual-studio-code"
        ])
        #expect(report.outdatedData.packages.map(\.kind) == [
            .formula,
            .formula,
            .cask
        ])
        #expect(report.packageMetadata.count == 7)
        #expect(report.commandResults.map(\.standardOutput) == [
            outdatedOutput,
            metadataOutput
        ])
    }

    @Test("Preserves malformed outdated data for troubleshooting")
    func preservesMalformedOutdatedData() {
        let runner = RecordingCommandRunner { request in
            .testResult(
                for: request,
                standardOutput: "{not-json}\n",
                standardError: "schema warning\n"
            )
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        do {
            _ = try service.outdatedData()
            Issue.record("Expected malformed outdated data to fail")
        } catch HomebrewError.invalidOutdatedData(let results) {
            #expect(results.map(\.standardOutput) == ["{not-json}\n"])
            #expect(results.map(\.standardError) == ["schema warning\n"])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Preserves malformed installed metadata for troubleshooting")
    func preservesMalformedPackageMetadata() throws {
        let outdatedOutput = try FixtureLoader.text(
            named: "outdated",
            fileExtension: "json"
        )
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["outdated", "--json=v2"]:
                return .testResult(for: request, standardOutput: outdatedOutput)
            case ["info", "--json=v2", "--installed"]:
                return .testResult(
                    for: request,
                    standardOutput: "{not-json}\n",
                    standardError: "metadata schema warning\n"
                )
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        do {
            _ = try service.outdatedData()
            Issue.record("Expected malformed installed metadata to fail")
        } catch HomebrewError.invalidPackageMetadata(let results) {
            #expect(results.map(\.standardOutput) == [
                outdatedOutput,
                "{not-json}\n"
            ])
            #expect(results.map(\.standardError) == [
                "",
                "metadata schema warning\n"
            ])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Preserves outdated output when installed metadata command fails")
    func preservesOutputBeforeMetadataCommandFailure() throws {
        let outdatedOutput = try FixtureLoader.text(
            named: "outdated",
            fileExtension: "json"
        )
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["outdated", "--json=v2"]:
                return .testResult(for: request, standardOutput: outdatedOutput)
            case ["info", "--json=v2", "--installed"]:
                return .testResult(
                    for: request,
                    standardOutput: "partial metadata\n",
                    standardError: "metadata command failed\n",
                    terminationStatus: 3
                )
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        do {
            _ = try service.outdatedData()
            Issue.record("Expected the metadata command to fail")
        } catch HomebrewError.commandFailed(let results) {
            #expect(results.map(\.standardOutput) == [
                outdatedOutput,
                "partial metadata\n"
            ])
            #expect(results.map(\.standardError) == [
                "",
                "metadata command failed\n"
            ])
            #expect(results.map(\.terminationStatus) == [0, 3])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Reports a missing Homebrew installation before running commands")
    func reportsMissingHomebrew() {
        let runner = RecordingCommandRunner { request in
            throw RecordingCommandRunnerError.unexpectedRequest(request)
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableLocator: HomebrewExecutableLocator { _ in false }
        )

        do {
            _ = try service.installedInventory()
            Issue.record("Expected Homebrew to be missing")
        } catch HomebrewError.notInstalled {
            // Expected failure.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(runner.requests.isEmpty)
    }
}
