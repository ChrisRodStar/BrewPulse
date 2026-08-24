import Foundation

enum HomebrewError: LocalizedError, Sendable {
    case notInstalled
    case commandFailed(results: [CommandResult])
    case commandTimedOut(results: [CommandResult])
    case invalidOutdatedData(results: [CommandResult])
    case invalidPackageMetadata(results: [CommandResult])

    var commandResults: [CommandResult] {
        switch self {
        case .notInstalled:
            return []
        case .commandFailed(let results),
             .commandTimedOut(let results),
             .invalidOutdatedData(let results),
             .invalidPackageMetadata(let results):
            return results
        }
    }

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Homebrew was not found. Install Homebrew, then refresh."
        case .commandFailed(let results):
            let message = results.last?.standardError
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return message.isEmpty ? "Homebrew command failed." : message
        case .commandTimedOut:
            return "Homebrew did not finish the refresh command within five minutes."
        case .invalidOutdatedData:
            return "Homebrew returned outdated-package data BrewPulse could not read."
        case .invalidPackageMetadata:
            return "Homebrew returned package metadata BrewPulse could not read."
        }
    }
}

struct HomebrewService: Sendable {
    private let commandRunner: any CommandRunning
    private let executableLocator: HomebrewExecutableLocator
    private let packageListParser: HomebrewPackageListParser
    private let outdatedDataParser: HomebrewOutdatedDataParser
    private let packageMetadataParser: HomebrewPackageMetadataParser
    private let versionParser: HomebrewVersionParser
    private let inventoryMerger: HomebrewInventoryMerger
    private let providedExecutableURL: URL?
    private let currentDate: @Sendable () -> Date
    private let refreshCommandPolicy: CommandExecutionPolicy

    nonisolated init(
        commandRunner: any CommandRunning = SerializedCommandRunner(
            base: ProcessCommandRunner()
        ),
        executableLocator: HomebrewExecutableLocator = HomebrewExecutableLocator(),
        packageListParser: HomebrewPackageListParser = HomebrewPackageListParser(),
        outdatedDataParser: HomebrewOutdatedDataParser = HomebrewOutdatedDataParser(),
        packageMetadataParser: HomebrewPackageMetadataParser = HomebrewPackageMetadataParser(),
        versionParser: HomebrewVersionParser = HomebrewVersionParser(),
        inventoryMerger: HomebrewInventoryMerger = HomebrewInventoryMerger(),
        executableURL: URL? = nil,
        refreshCommandTimeout: Duration = .seconds(300),
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.commandRunner = commandRunner
        self.executableLocator = executableLocator
        self.packageListParser = packageListParser
        self.outdatedDataParser = outdatedDataParser
        self.packageMetadataParser = packageMetadataParser
        self.versionParser = versionParser
        self.inventoryMerger = inventoryMerger
        self.providedExecutableURL = executableURL
        refreshCommandPolicy = .timeout(after: refreshCommandTimeout)
        self.currentDate = currentDate
    }

    nonisolated func installedInventory() throws -> HomebrewInventoryReport {
        let brewURL = try executableURL()
        return try installedInventory(at: brewURL)
    }

    nonisolated func inventoryWithUpdateAvailability() throws -> HomebrewInventoryReport {
        let brewURL = try executableURL()
        let inventoryReport = try installedInventory(at: brewURL)
        let outdatedReport = try outdatedData(
            at: brewURL,
            previousResults: inventoryReport.commandResults
        )

        return HomebrewInventoryReport(
            inventory: inventoryMerger.merge(
                inventory: inventoryReport.inventory,
                outdatedPackages: outdatedReport.outdatedData.packages,
                packageMetadata: outdatedReport.packageMetadata
            ),
            commandResults: inventoryReport.commandResults + outdatedReport.commandResults,
            refreshedAt: currentDate(),
            homebrewVersion: inventoryReport.homebrewVersion
        )
    }

    nonisolated func operationCommand(
        for package: HomebrewPackage,
        operation: HomebrewPackageOperationKind
    ) throws -> CommandRequest {
        try HomebrewPackageOperationCommandBuilder().request(
            executableURL: executableURL(),
            package: package,
            operation: operation
        )
    }

    nonisolated func updateAllCommand(
        for packages: [HomebrewPackage]
    ) throws -> CommandRequest {
        try HomebrewPackageOperationCommandBuilder().updateAllRequest(
            executableURL: executableURL(),
            packages: packages
        )
    }

    nonisolated func runOperation(
        _ plan: HomebrewPackageOperationPlan
    ) throws -> CommandResult {
        let result = try commandRunner.run(plan.command)
        guard result.terminationStatus == 0 else {
            throw HomebrewError.commandFailed(results: [result])
        }
        return result
    }

    nonisolated func runOperation(
        _ plan: HomebrewOperationPlan
    ) throws -> CommandResult {
        let result = try commandRunner.run(plan.command)
        guard result.terminationStatus == 0 else {
            throw HomebrewError.commandFailed(results: [result])
        }
        return result
    }

    nonisolated func cancelCurrentCommand() {
        commandRunner.cancelCurrentCommand()
    }

    nonisolated private func installedInventory(
        at brewURL: URL
    ) throws -> HomebrewInventoryReport {
        let applications = try packages(
            at: brewURL,
            kind: .cask,
            previousResults: []
        )
        let formulae = try packages(
            at: brewURL,
            kind: .formula,
            previousResults: [applications.commandResult]
        )
        let version = try homebrewVersion(
            at: brewURL,
            previousResults: [
                applications.commandResult,
                formulae.commandResult
            ]
        )

        return HomebrewInventoryReport(
            inventory: HomebrewInventory(
                applications: applications.packages,
                formulae: formulae.packages
            ),
            commandResults: [
                applications.commandResult,
                formulae.commandResult,
                version.commandResult
            ],
            refreshedAt: currentDate(),
            homebrewVersion: version.value
        )
    }

    nonisolated private func homebrewVersion(
        at brewURL: URL,
        previousResults: [CommandResult]
    ) throws -> (value: String?, commandResult: CommandResult) {
        let result = try runRefreshCommand(
            CommandRequest(executableURL: brewURL, arguments: ["--version"]),
            previousResults: previousResults
        )

        guard result.terminationStatus == 0 else {
            throw HomebrewError.commandFailed(results: previousResults + [result])
        }

        return (versionParser.parse(result.standardOutput), result)
    }

    nonisolated func outdatedData() throws -> HomebrewOutdatedReport {
        let brewURL = try executableURL()
        return try outdatedData(at: brewURL, previousResults: [])
    }

    nonisolated private func outdatedData(
        at brewURL: URL,
        previousResults: [CommandResult]
    ) throws -> HomebrewOutdatedReport {
        let result = try runRefreshCommand(
            CommandRequest(
                executableURL: brewURL,
                arguments: ["outdated", "--json=v2"]
            ),
            previousResults: previousResults
        )

        guard result.terminationStatus == 0 else {
            throw HomebrewError.commandFailed(results: previousResults + [result])
        }

        let outdatedData: HomebrewOutdatedData
        do {
            outdatedData = try outdatedDataParser.parse(result.standardOutput)
        } catch {
            throw HomebrewError.invalidOutdatedData(results: previousResults + [result])
        }

        let metadataResult = try runRefreshCommand(
            CommandRequest(
                executableURL: brewURL,
                arguments: ["info", "--json=v2", "--installed"]
            ),
            previousResults: previousResults + [result]
        )

        guard metadataResult.terminationStatus == 0 else {
            throw HomebrewError.commandFailed(
                results: previousResults + [result, metadataResult]
            )
        }

        do {
            return HomebrewOutdatedReport(
                outdatedData: outdatedData,
                packageMetadata: try packageMetadataParser.parse(
                    metadataResult.standardOutput
                ).packages,
                commandResults: [result, metadataResult]
            )
        } catch {
            throw HomebrewError.invalidPackageMetadata(
                results: previousResults + [result, metadataResult]
            )
        }
    }

    nonisolated private func executableURL() throws -> URL {
        if let providedExecutableURL {
            return providedExecutableURL
        }

        guard let executableURL = executableLocator.locate() else {
            throw HomebrewError.notInstalled
        }
        return executableURL
    }

    nonisolated private func packages(
        at brewURL: URL,
        kind: HomebrewPackage.Kind,
        previousResults: [CommandResult]
    ) throws -> (packages: [HomebrewPackage], commandResult: CommandResult) {
        let arguments = [
            "list",
            kind == .formula ? "--formula" : "--cask",
            "--versions"
        ]

        let result = try runRefreshCommand(
            CommandRequest(
                executableURL: brewURL,
                arguments: arguments
            ),
            previousResults: previousResults
        )

        guard result.terminationStatus == 0 else {
            throw HomebrewError.commandFailed(results: previousResults + [result])
        }

        return (
            packageListParser.parse(result.standardOutput, kind: kind),
            result
        )
    }

    nonisolated private func runRefreshCommand(
        _ request: CommandRequest,
        previousResults: [CommandResult]
    ) throws -> CommandResult {
        let result = try commandRunner.run(
            request,
            policy: refreshCommandPolicy
        )
        if result.terminationReason == .timedOut {
            throw HomebrewError.commandTimedOut(
                results: previousResults + [result]
            )
        }
        return result
    }
}
