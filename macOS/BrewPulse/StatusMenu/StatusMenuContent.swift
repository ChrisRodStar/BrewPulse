import SwiftUI

struct StatusMenuContent: View {
    @State private var selectedSection = StatusMenuSection.status

    let state: PackageStore.State
    let packageActionsDisabled: Bool
    let onRefresh: () -> Void
    let onShowRefreshFailureDetails: (PackageStore.Failure) -> Void
    let onUpdate: (HomebrewPackage.ID) -> Void
    let onUninstall: (HomebrewPackage.ID) -> Void

    var body: some View {
        if let report = state.report {
            RetainedPackageContent(
                report: report,
                state: state,
                selectedSection: $selectedSection,
                packageActionsDisabled: packageActionsDisabled,
                onShowRefreshFailureDetails: onShowRefreshFailureDetails,
                onUpdate: onUpdate,
                onUninstall: onUninstall
            )
        } else {
            InitialPackageContent(
                state: state,
                onRefresh: onRefresh,
                onShowRefreshFailureDetails: onShowRefreshFailureDetails
            )
        }
    }
}

private struct InitialPackageContent: View {
    let state: PackageStore.State
    let onRefresh: () -> Void
    let onShowRefreshFailureDetails: (PackageStore.Failure) -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            ContentUnavailableView {
                ProgressView()
            } description: {
                Text("Loading installed Homebrew packages…")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let failure, previousReport: nil):
            InitialRefreshFailureView(
                failure: failure,
                onRefresh: onRefresh,
                onShowDetails: { onShowRefreshFailureDetails(failure) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded, .refreshing, .failed(_, previousReport: .some):
            EmptyView()
        }
    }
}

private struct RetainedPackageContent: View {
    let report: HomebrewInventoryReport
    let state: PackageStore.State
    @Binding var selectedSection: StatusMenuSection
    let packageActionsDisabled: Bool
    let onShowRefreshFailureDetails: (PackageStore.Failure) -> Void
    let onUpdate: (HomebrewPackage.ID) -> Void
    let onUninstall: (HomebrewPackage.ID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            StatusMenuSectionPicker(
                selection: $selectedSection,
                inventory: report.inventory
            )
            .padding(12)

            Divider()
            RefreshStatus(
                state: state,
                retainedAt: report.refreshedAt,
                onShowRefreshFailureDetails: onShowRefreshFailureDetails
            )

            switch selectedSection {
            case .status:
                HomebrewStatusView(report: report)
            case .casks:
                PackageInventoryList(
                    category: .casks,
                    packages: report.inventory.applications,
                    packageActionsDisabled: packageActionsDisabled,
                    onUpdate: onUpdate,
                    onUninstall: onUninstall
                )
            case .formulae:
                PackageInventoryList(
                    category: .formulae,
                    packages: report.inventory.formulae,
                    packageActionsDisabled: packageActionsDisabled,
                    onUpdate: onUpdate,
                    onUninstall: onUninstall
                )
            }
        }
    }
}

private struct RefreshStatus: View {
    let state: PackageStore.State
    let retainedAt: Date
    let onShowRefreshFailureDetails: (PackageStore.Failure) -> Void

    var body: some View {
        switch state {
        case .refreshing:
            ProgressView()
                .progressViewStyle(.linear)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .accessibilityLabel("Refreshing package information")
        case .failed(let failure, previousReport: .some):
            RefreshFailureBanner(
                failure: failure,
                retainedAt: retainedAt,
                onShowDetails: { onShowRefreshFailureDetails(failure) }
            )
        case .idle, .loading, .loaded, .failed(_, previousReport: nil):
            EmptyView()
        }
    }
}

#if DEBUG
private enum StatusMenuContentPreviewData {
    static let emptyReport = HomebrewInventoryReport(
        inventory: HomebrewInventory(applications: [], formulae: []),
        commandResults: [],
        refreshedAt: .now,
        homebrewVersion: "5.0.0"
    )

    static let failedCommandResult: CommandResult = {
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
            arguments: ["outdated", "--json=v2"]
        )
        return CommandResult(
            request: request,
            standardOutput: "Checking installed packages…\n",
            standardError: "curl: (6) Could not resolve host: formulae.brew.sh\n",
            terminationStatus: 1,
            startedAt: .now,
            duration: .seconds(2)
        )
    }()

    static let missingHomebrewFailure = PackageStore.Failure(
        homebrewError: .notInstalled
    )

    static let commandFailure = PackageStore.Failure(
        homebrewError: .commandFailed(results: [failedCommandResult])
    )
}

private extension StatusMenuContent {
    static func preview(state: PackageStore.State) -> StatusMenuContent {
        StatusMenuContent(
            state: state,
            packageActionsDisabled: false,
            onRefresh: {},
            onShowRefreshFailureDetails: { _ in },
            onUpdate: { _ in },
            onUninstall: { _ in }
        )
    }
}

#Preview("Missing Homebrew") {
    StatusMenuContent.preview(
        state: .failed(
            StatusMenuContentPreviewData.missingHomebrewFailure,
            previousReport: nil
        )
    )
    .frame(width: 400, height: 460)
}

#Preview("Loading") {
    StatusMenuContent.preview(state: .loading)
        .frame(width: 400, height: 460)
}

#Preview("Initial refresh failure") {
    StatusMenuContent.preview(
        state: .failed(
            StatusMenuContentPreviewData.commandFailure,
            previousReport: nil
        )
    )
    .frame(width: 400, height: 460)
}

#Preview("Retained data after refresh failure") {
    StatusMenuContent.preview(
        state: .failed(
            StatusMenuContentPreviewData.commandFailure,
            previousReport: StatusMenuContentPreviewData.emptyReport
        )
    )
    .frame(width: 400, height: 460)
}

#Preview("Empty inventory") {
    StatusMenuContent.preview(
        state: .loaded(StatusMenuContentPreviewData.emptyReport)
    )
    .frame(width: 400, height: 460)
}
#endif
