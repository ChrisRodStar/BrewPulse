import SwiftUI

struct StatusMenuContent: View {
    @State private var selectedSection = StatusMenuSection.status

    let state: PackageStore.State
    let packageActionsDisabled: Bool
    let onUpdate: (HomebrewPackage.ID) -> Void
    let onUninstall: (HomebrewPackage.ID) -> Void

    var body: some View {
        if let report = state.report {
            RetainedPackageContent(
                report: report,
                state: state,
                selectedSection: $selectedSection,
                packageActionsDisabled: packageActionsDisabled,
                onUpdate: onUpdate,
                onUninstall: onUninstall
            )
        } else {
            InitialPackageContent(state: state)
        }
    }
}

private struct InitialPackageContent: View {
    let state: PackageStore.State

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
            ContentUnavailableView(
                "Unable to Load Packages",
                systemImage: "exclamationmark.triangle",
                description: Text(failure.message)
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
            RefreshStatus(state: state)

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

    var body: some View {
        switch state {
        case .refreshing:
            ProgressView()
                .progressViewStyle(.linear)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .accessibilityLabel("Refreshing package information")
        case .failed(let failure, previousReport: .some):
            RefreshFailureBanner(message: failure.message)
        case .idle, .loading, .loaded, .failed(_, previousReport: nil):
            EmptyView()
        }
    }
}
