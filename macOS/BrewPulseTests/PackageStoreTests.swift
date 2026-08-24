import Foundation
import Testing
@testable import BrewPulse

@Suite("Package store")
struct PackageStoreTests {
    private let brewURL = URL(fileURLWithPath: "/test/homebrew/bin/brew")

    @Test("Retains successful Homebrew command output after refresh")
    @MainActor
    func retainsSuccessfulCommandOutput() async throws {
        let refreshedAt = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let casksOutput = try FixtureLoader.text(named: "casks")
        let formulaeOutput = try FixtureLoader.text(named: "formulae")
        let outdatedOutput = try FixtureLoader.text(
            named: "outdated",
            fileExtension: "json"
        )
        let metadataOutput = try FixtureLoader.text(
            named: "installed-metadata",
            fileExtension: "json"
        )
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["list", "--cask", "--versions"]:
                return .testResult(
                    for: request,
                    standardOutput: casksOutput,
                    standardError: "cask warning\n"
                )
            case ["list", "--formula", "--versions"]:
                return .testResult(for: request, standardOutput: formulaeOutput)
            case ["--version"]:
                return .testResult(for: request, standardOutput: "Homebrew 5.0.0\n")
            case ["outdated", "--json=v2"]:
                return .testResult(for: request, standardOutput: outdatedOutput)
            case ["info", "--json=v2", "--installed"]:
                return .testResult(for: request, standardOutput: metadataOutput)
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let store = PackageStore(
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL,
                currentDate: { refreshedAt }
            )
        )

        await store.refresh()

        guard case .loaded(let report) = store.state else {
            Issue.record("Expected the package store to load")
            return
        }
        #expect(report.inventory.count == 8)
        #expect(report.homebrewVersion == "5.0.0")
        #expect(report.refreshedAt == refreshedAt)
        let git = try #require(
            report.inventory.formulae.first { $0.name == "git" }
        )
        #expect(git.versions.available == "2.50.1")
        #expect(report.commandResults.map(\.standardOutput) == [
            casksOutput,
            formulaeOutput,
            "Homebrew 5.0.0\n",
            outdatedOutput,
            metadataOutput
        ])
        #expect(report.commandResults.map(\.standardError) == [
            "cask warning\n",
            "",
            "",
            "",
            ""
        ])
    }

    @Test("Retains failed Homebrew command output after refresh")
    @MainActor
    func retainsFailedCommandOutput() async {
        let runner = RecordingCommandRunner { request in
            .testResult(
                for: request,
                standardOutput: "partial output\n",
                standardError: "  permission denied\n",
                terminationStatus: 1
            )
        }
        let store = PackageStore(
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )

        await store.refresh()

        guard case .failed(let failure, previousReport: nil) = store.state else {
            Issue.record("Expected the package store to fail")
            return
        }
        #expect(failure.kind == .commandFailed)
        #expect(failure.message == "permission denied")
        #expect(failure.commandResults.map(\.standardOutput) == ["partial output\n"])
        #expect(failure.commandResults.map(\.standardError) == ["  permission denied\n"])
    }

    @Test("Reports missing Homebrew with every searched executable path")
    @MainActor
    func reportsMissingHomebrewPaths() async {
        let runner = RecordingCommandRunner { request in
            throw RecordingCommandRunnerError.unexpectedRequest(request)
        }
        let store = PackageStore(
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableLocator: HomebrewExecutableLocator { _ in false }
            )
        )

        await store.refresh()

        guard case .failed(let failure, previousReport: nil) = store.state else {
            Issue.record("Expected a missing Homebrew failure")
            return
        }
        #expect(failure.kind == .homebrewNotInstalled)
        #expect(
            failure.searchedExecutablePaths
                == HomebrewExecutableLocator.candidatePaths
        )
        #expect(failure.commandResults.isEmpty)
        #expect(runner.requests.isEmpty)
    }

    @Test("Classifies refresh failures without discarding their command output")
    @MainActor
    func classifiesRefreshFailures() {
        let request = CommandRequest(
            executableURL: brewURL,
            arguments: ["outdated", "--json=v2"]
        )
        let connectivityResult = CommandResult.testResult(
            for: request,
            standardOutput: "partial output\n",
            standardError: "curl: (6) Could not resolve host: formulae.brew.sh\n",
            terminationStatus: 1
        )
        let ordinaryFailureResult = CommandResult.testResult(
            for: request,
            standardError: "permission denied\n",
            terminationStatus: 1
        )

        let connectivityFailure = PackageStore.Failure(
            homebrewError: .commandFailed(results: [connectivityResult])
        )
        let commandFailure = PackageStore.Failure(
            homebrewError: .commandFailed(results: [ordinaryFailureResult])
        )
        let timeoutFailure = PackageStore.Failure(
            homebrewError: .commandTimedOut(results: [ordinaryFailureResult])
        )
        let outdatedDataFailure = PackageStore.Failure(
            homebrewError: .invalidOutdatedData(results: [ordinaryFailureResult])
        )
        let metadataFailure = PackageStore.Failure(
            homebrewError: .invalidPackageMetadata(results: [ordinaryFailureResult])
        )

        #expect(connectivityFailure.kind == .connectivityFailure)
        #expect(connectivityFailure.commandResults == [connectivityResult])
        #expect(commandFailure.kind == .commandFailed)
        #expect(timeoutFailure.kind == .commandTimedOut)
        #expect(outdatedDataFailure.kind == .unreadableOutdatedData)
        #expect(metadataFailure.kind == .unreadablePackageMetadata)
    }

    @Test("Formats complete failed refresh details for copying")
    func formatsFailedRefreshDetailsForCopying() {
        let request = CommandRequest(
            executableURL: brewURL,
            arguments: ["outdated", "--json=v2"]
        )
        let result = CommandResult.testResult(
            for: request,
            standardOutput: "partial output\n",
            standardError: "network unavailable\n",
            terminationStatus: 7
        )

        let output = RefreshFailureOutputFormatter().string(for: [result])

        #expect(output.contains("Exact command: /test/homebrew/bin/brew outdated --json=v2"))
        #expect(output.contains("Exit status: 7"))
        #expect(output.contains("Standard output:\npartial output\n"))
        #expect(output.contains("Standard error:\nnetwork unavailable\n"))
    }

    @Test("Preserves the previous report while refreshing")
    @MainActor
    func preservesPreviousReportWhileRefreshing() async throws {
        let previousReport = Self.sampleReport
        let runner = SuspendedCommandRunner { request in
            switch request.arguments {
            case ["list", "--cask", "--versions"],
                 ["list", "--formula", "--versions"],
                 ["--version"]:
                return .testResult(for: request)
            case ["outdated", "--json=v2"],
                 ["info", "--json=v2", "--installed"]:
                return .testResult(for: request, standardOutput: "{}")
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let store = PackageStore(
            state: .loaded(previousReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )
        let package = try #require(previousReport.inventory.formulae.first)
        let updatePlan = try store.operationPlan(for: package.id, kind: .update)
        try store.confirmOperation(updatePlan)
        #expect(store.confirmedOperationPlan == updatePlan)

        let refresh = Task { await store.refresh() }
        for _ in 0..<100 where store.state != .refreshing(previousReport) {
            await Task.yield()
        }

        #expect(store.state == .refreshing(previousReport))
        #expect(store.state.report == previousReport)
        #expect(store.state.availableUpdateCount == 1)
        #expect(store.confirmedOperationPlan == nil)
        #expect(store.isPerformingHomebrewWork)

        runner.resume()
        await refresh.value
    }

    @Test("Preserves the previous report when refresh fails")
    @MainActor
    func preservesPreviousReportWhenRefreshFails() async {
        let previousReport = Self.sampleReport
        let runner = RecordingCommandRunner { request in
            .testResult(
                for: request,
                standardError: "network unavailable\n",
                terminationStatus: 1
            )
        }
        let store = PackageStore(
            state: .loaded(previousReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )

        await store.refresh()

        guard case .failed(
            let failure,
            previousReport: .some(let retainedReport)
        ) = store.state else {
            Issue.record("Expected refresh failure with the previous report")
            return
        }
        #expect(failure.message == "network unavailable")
        #expect(failure.kind == .connectivityFailure)
        #expect(retainedReport == previousReport)
        #expect(store.state.availableUpdateCount == 1)
    }

    @Test("Prepares update plans only for eligible packages in the latest report")
    @MainActor
    func validatesUpdatePlansAgainstLatestReport() throws {
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(executableURL: brewURL)
        )
        let package = try #require(Self.sampleReport.inventory.formulae.first)

        let plan = try store.operationPlan(for: package.id, kind: .update)

        #expect(plan == HomebrewPackageOperationPlan(
            kind: .update,
            package: package,
            command: CommandRequest(
                executableURL: brewURL,
                arguments: ["upgrade", "--formula", "--", "git"]
            )
        ))

        let unavailableID = HomebrewPackage.ID(
            kind: .formula,
            name: "not-installed"
        )
        #expect(throws: HomebrewPackageOperationConfirmationError.planChanged(
            unavailableID
        )) {
            try store.operationPlan(for: unavailableID, kind: .update)
        }

        let blockedPackage = HomebrewPackage(
            name: "openssl@3",
            versions: HomebrewPackageVersions(
                installed: ["3.5.2"],
                available: "3.5.4"
            ),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility(
                blockers: [.pinned(version: "3.5.2")]
            )
        )
        let blockedStore = PackageStore(
            state: .loaded(
                HomebrewInventoryReport(
                    inventory: HomebrewInventory(
                        applications: [],
                        formulae: [blockedPackage]
                    ),
                    commandResults: [],
                    refreshedAt: .now
                )
            ),
            homebrewService: HomebrewService(executableURL: brewURL)
        )

        #expect(throws: HomebrewPackageOperationCommandError.upgradeUnavailable(
            blockedPackage.id
        )) {
            try blockedStore.operationPlan(
                for: blockedPackage.id,
                kind: .update
            )
        }
    }

    @Test("Confirms only an unchanged plan from the latest report")
    @MainActor
    func validatesPlanBeforeConfirmation() throws {
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(executableURL: brewURL)
        )
        let package = try #require(Self.sampleReport.inventory.formulae.first)
        let plan = try store.operationPlan(for: package.id, kind: .update)

        try store.confirmOperation(plan)

        #expect(store.confirmedOperationPlan == plan)

        let changedPlan = HomebrewPackageOperationPlan(
            kind: .update,
            package: package,
            command: CommandRequest(
                executableURL: brewURL,
                arguments: ["upgrade", "--formula", "--", "different-package"]
            )
        )
        #expect(throws: HomebrewPackageOperationConfirmationError.planChanged(package.id)) {
            try store.confirmOperation(changedPlan)
        }
        #expect(store.confirmedOperationPlan == plan)
    }

    @Test("Builds, confirms, and runs Update All as one reviewed command")
    @MainActor
    func runsConfirmedUpdateAll() async throws {
        let runner = RecordingCommandRunner { request in
            if request.arguments == ["upgrade", "--", "git"] {
                return .testResult(
                    for: request,
                    standardOutput: "Upgraded all eligible packages\n"
                )
            }
            return try Self.successfulRefreshResult(for: request)
        }
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )

        let plan = try store.updateAllOperationPlan()
        guard case .updateAll(let updateAllPlan) = plan else {
            Issue.record("Expected an Update All plan")
            return
        }
        #expect(updateAllPlan.packages.map(\.name) == ["git"])
        #expect(updateAllPlan.command.arguments == ["upgrade", "--", "git"])

        try store.confirmOperation(plan)
        #expect(store.confirmedUpdateAllPlan == updateAllPlan)

        await store.runConfirmedOperation()

        guard case .completed(let completedPlan, let result) = store.operationState else {
            Issue.record("Expected Update All to complete")
            return
        }
        #expect(completedPlan == plan)
        #expect(result.request.arguments == ["upgrade", "--", "git"])
        #expect(result.standardOutput == "Upgraded all eligible packages\n")
        #expect(runner.requests.first?.arguments == ["upgrade", "--", "git"])
    }

    @Test("Rejects Update All without a fresh actionable report")
    @MainActor
    func rejectsUnavailableUpdateAllPlans() {
        let emptyReport = HomebrewInventoryReport(
            inventory: HomebrewInventory(applications: [], formulae: []),
            commandResults: [],
            refreshedAt: .now
        )
        let failedStore = PackageStore(
            state: .failed(
                PackageStore.Failure(
                    unexpectedError: CocoaError(.fileReadUnknown)
                ),
                previousReport: Self.sampleReport
            ),
            homebrewService: HomebrewService(executableURL: brewURL)
        )
        let emptyStore = PackageStore(
            state: .loaded(emptyReport),
            homebrewService: HomebrewService(executableURL: brewURL)
        )

        #expect(throws: (any Error).self) {
            try failedStore.updateAllOperationPlan()
        }
        #expect(throws: (any Error).self) {
            try emptyStore.updateAllOperationPlan()
        }
    }

    @Test("Identifies the package while its confirmed update is running")
    @MainActor
    func tracksRunningUpdate() async throws {
        let expectedOutput = "updating git\n"
        let runner = SuspendedCommandRunner { request in
            if request.arguments == ["upgrade", "--formula", "--", "git"] {
                return .testResult(
                    for: request,
                    standardOutput: expectedOutput
                )
            }
            return try Self.successfulRefreshResult(for: request)
        }
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )
        let package = try #require(Self.sampleReport.inventory.formulae.first)
        let plan = try store.operationPlan(for: package.id, kind: .update)
        try store.confirmOperation(plan)

        let update = Task { await store.runConfirmedOperation() }
        for _ in 0..<100 where store.operationState.runningPlan != .package(plan) {
            await Task.yield()
        }

        #expect(store.operationState == .running(.package(plan)))
        #expect(store.isPerformingHomebrewWork)
        #expect(throws: HomebrewPackageOperationConfirmationError.operationInProgress(plan.id)) {
            try store.operationPlan(for: plan.id, kind: .uninstall)
        }
        #expect(throws: HomebrewPackageOperationConfirmationError.operationInProgress(plan.id)) {
            try store.confirmOperation(plan)
        }

        runner.resume()
        await update.value

        guard case .completed(let completedPlan, let result) = store.operationState else {
            Issue.record("Expected the update to complete")
            return
        }
        #expect(completedPlan == .package(plan))
        #expect(result.request == plan.command)
        #expect(result.standardOutput == expectedOutput)
        #expect(store.operationState.terminalOutput?.status == .succeeded)
        #expect(store.state.report?.inventory.formulae.map(\.name) == ["git"])
        #expect(runner.requests.map(\.arguments) == [
            ["upgrade", "--formula", "--", "git"],
            ["list", "--cask", "--versions"],
            ["list", "--formula", "--versions"],
            ["--version"],
            ["outdated", "--json=v2"],
            ["info", "--json=v2", "--installed"]
        ])
        #expect(!store.isPerformingHomebrewWork)
    }

    @Test("Separates a successful package action from a failed inventory refresh")
    @MainActor
    func preservesSuccessfulOperationWhenFollowUpRefreshFails() async throws {
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["upgrade", "--formula", "--", "git"]:
                .testResult(
                    for: request,
                    standardOutput: "git was upgraded\n"
                )
            case ["list", "--cask", "--versions"]:
                .testResult(
                    for: request,
                    standardError: "Could not resolve host: formulae.brew.sh\n",
                    terminationStatus: 1
                )
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )
        let package = try #require(Self.sampleReport.inventory.formulae.first)
        let plan = try store.operationPlan(for: package.id, kind: .update)
        try store.confirmOperation(plan)

        await store.runConfirmedOperation()

        guard case .completed(let completedPlan, let operationResult) =
            store.operationState else {
            Issue.record("Expected the package action to remain successful")
            return
        }
        #expect(completedPlan == .package(plan))
        #expect(operationResult.standardOutput == "git was upgraded\n")
        #expect(store.operationFollowUpRefreshFailure?.kind == .connectivityFailure)

        guard case .failed(let refreshFailure, let previousReport) = store.state else {
            Issue.record("Expected the follow-up refresh to fail separately")
            return
        }
        #expect(refreshFailure.kind == .connectivityFailure)
        #expect(previousReport == Self.sampleReport)
        #expect(store.state.report == Self.sampleReport)
        #expect(runner.requests.map(\.arguments) == [
            ["upgrade", "--formula", "--", "git"],
            ["list", "--cask", "--versions"]
        ])
    }

    @Test("Preserves a failed update's original output and refreshes packages")
    @MainActor
    func preservesFailedUpdateOutput() async throws {
        let runner = RecordingCommandRunner { request in
            if request.arguments == ["upgrade", "--formula", "--", "git"] {
                return .testResult(
                    for: request,
                    standardOutput: "partial update\n",
                    standardError: "permission denied\n",
                    terminationStatus: 1
                )
            }
            return try Self.successfulRefreshResult(for: request)
        }
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )
        let package = try #require(Self.sampleReport.inventory.formulae.first)
        let plan = try store.operationPlan(for: package.id, kind: .update)
        try store.confirmOperation(plan)

        await store.runConfirmedOperation()

        guard case .failed(
            let failedPlan,
            let message,
            let result
        ) = store.operationState else {
            Issue.record("Expected the update to fail")
            return
        }
        #expect(failedPlan == .package(plan))
        #expect(message == "permission denied")
        #expect(result?.standardOutput == "partial update\n")
        #expect(result?.standardError == "permission denied\n")
        #expect(store.state.report?.inventory.formulae.map(\.name) == ["git"])
        #expect(runner.requests.count == 6)
    }

    @Test("Runs a confirmed uninstall and refreshes the removed package")
    @MainActor
    func runsConfirmedUninstall() async throws {
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["uninstall", "--formula", "--", "git"]:
                .testResult(
                    for: request,
                    standardOutput: "Uninstalling /test/git...\n"
                )
            case ["list", "--cask", "--versions"],
                 ["list", "--formula", "--versions"]:
                .testResult(for: request)
            case ["--version"]:
                .testResult(for: request, standardOutput: "Homebrew 5.0.0\n")
            case ["outdated", "--json=v2"],
                 ["info", "--json=v2", "--installed"]:
                .testResult(
                    for: request,
                    standardOutput: #"{"formulae":[],"casks":[]}"#
                )
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )
        let package = try #require(Self.sampleReport.inventory.formulae.first)
        let plan = try store.operationPlan(for: package.id, kind: .uninstall)

        #expect(plan.command.arguments == [
            "uninstall", "--formula", "--", "git"
        ])
        try store.confirmOperation(plan)
        await store.runConfirmedOperation()

        guard case .completed(let completedPlan, let result) = store.operationState else {
            Issue.record("Expected the uninstall to complete")
            return
        }
        #expect(completedPlan == .package(plan))
        #expect(result.standardOutput == "Uninstalling /test/git...\n")
        #expect(store.state.report?.inventory.count == 0)
        #expect(store.operationState.terminalOutput?.plan.kind == .uninstall)
        #expect(runner.requests.first?.arguments == [
            "uninstall", "--formula", "--", "git"
        ])
    }

    @Test("Cancels an active update safely and preserves partial output")
    @MainActor
    func cancelsActiveUpdate() async throws {
        let runner = SuspendedCommandRunner { request in
            if request.arguments == ["upgrade", "--formula", "--", "git"] {
                return .testResult(
                    for: request,
                    standardOutput: "partial update before cancellation\n",
                    standardError: "interrupted\n",
                    terminationStatus: 130
                )
            }
            return try Self.successfulRefreshResult(for: request)
        }
        let store = PackageStore(
            state: .loaded(Self.sampleReport),
            homebrewService: HomebrewService(
                commandRunner: runner,
                executableURL: brewURL
            )
        )
        let package = try #require(Self.sampleReport.inventory.formulae.first)
        let plan = try store.operationPlan(for: package.id, kind: .update)
        try store.confirmOperation(plan)

        let update = Task { await store.runConfirmedOperation() }
        for _ in 0..<100 where store.operationState.runningPlan != .package(plan) {
            await Task.yield()
        }

        store.cancelOperation()

        #expect(store.operationState == .cancelling(.package(plan)))
        #expect(store.isPerformingHomebrewWork)
        #expect(runner.cancellationRequested)

        runner.resume()
        await update.value

        guard case .cancelled(
            let cancelledPlan,
            let result
        ) = store.operationState else {
            Issue.record("Expected the update to be cancelled")
            return
        }
        #expect(cancelledPlan == .package(plan))
        #expect(result?.standardOutput == "partial update before cancellation\n")
        #expect(result?.standardError == "interrupted\n")
        #expect(store.state.report?.inventory.formulae.map(\.name) == ["git"])
        #expect(runner.requests.count == 6)
        #expect(!store.isPerformingHomebrewWork)
    }

    nonisolated private static func successfulRefreshResult(
        for request: CommandRequest
    ) throws -> CommandResult {
        switch request.arguments {
        case ["list", "--cask", "--versions"]:
            .testResult(for: request)
        case ["list", "--formula", "--versions"]:
            .testResult(for: request, standardOutput: "git 2.50.1\n")
        case ["--version"]:
            .testResult(for: request, standardOutput: "Homebrew 5.0.0\n")
        case ["outdated", "--json=v2"],
             ["info", "--json=v2", "--installed"]:
            .testResult(
                for: request,
                standardOutput: #"{"formulae":[],"casks":[]}"#
            )
        default:
            throw RecordingCommandRunnerError.unexpectedRequest(request)
        }
    }

    private static let sampleReport = HomebrewInventoryReport(
        inventory: HomebrewInventory(
            applications: [],
            formulae: [
                HomebrewPackage(
                    name: "git",
                    versions: HomebrewPackageVersions(
                        installed: ["2.49.0"],
                        available: "2.50.1"
                    ),
                    kind: .formula,
                    upgradeEligibility: HomebrewPackageUpgradeEligibility()
                )
            ]
        ),
        commandResults: [],
        refreshedAt: Date(timeIntervalSinceReferenceDate: 800_000_000)
    )
}
