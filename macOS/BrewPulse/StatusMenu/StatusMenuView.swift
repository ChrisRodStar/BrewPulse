import AppKit
import SwiftUI

struct StatusMenuView: View {
    @Environment(PackageStore.self) private var store
    @Environment(ApplicationPresentationController.self)
    private var applicationPresentation
    @Environment(PackageOperationReviewPresentation.self)
    private var operationReviewPresentation
    @Environment(\.openWindow) private var openWindow
    @State private var presentedSheet: PresentedStatusMenuSheet?
    @State private var operationPreparationErrorMessage = ""
    @State private var isShowingOperationPreparationError = false

    var body: some View {
        VStack(spacing: 0) {
            StatusMenuHeader()
            Divider()
            if let activePlan = store.operationState.activePlan {
                PackageOperationProgressBanner(
                    plan: activePlan,
                    isCancelling: store.operationState.isCancelling,
                    onCancel: store.cancelOperation
                )
                Divider()
            } else if let output = store.operationState.terminalOutput {
                PackageOperationOutputBanner(
                    output: output,
                    followUpRefreshFailure: store.operationFollowUpRefreshFailure
                ) {
                    presentedSheet = PresentedStatusMenuSheet(
                        content: .operationOutput(
                            output,
                            followUpRefreshFailure: store.operationFollowUpRefreshFailure
                        )
                    )
                }
                Divider()
            }
            StatusMenuContent(
                state: store.state,
                packageActionsDisabled: store.isPerformingHomebrewWork,
                onRefresh: refresh,
                onShowRefreshFailureDetails: {
                    presentedSheet = PresentedStatusMenuSheet(
                        content: .refreshFailure($0)
                    )
                },
                onUpdate: { prepareOperation(for: $0, kind: .update) },
                onUninstall: { prepareOperation(for: $0, kind: .uninstall) }
            )
            Divider()
            HStack {
                Button {
                    refresh()
                } label: {
                    Label(
                        store.state.isLoading ? "Refreshing…" : "Refresh",
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(store.isPerformingHomebrewWork)
                .help(
                    store.isPerformingHomebrewWork
                        ? "Wait for the current Homebrew operation to finish"
                        : "Refresh package information"
                )

                Spacer()

                OpenSettingsButton()

                Button("Quit BrewPulse") {
                    NSApplication.shared.terminate(nil)
                }
                .disabled(store.operationState.isActive)
                .help(
                    store.operationState.isActive
                        ? "Cancel the Homebrew operation before quitting"
                        : "Quit BrewPulse"
                )
            }
            .padding(12)
        }
        .frame(width: 400, height: 520)
        .task {
            if case .idle = store.state {
                await store.refresh()
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet.content {
            case .operationOutput(let output, let followUpRefreshFailure):
                PackageOperationOutputDetails(
                    output: output,
                    followUpRefreshFailure: followUpRefreshFailure
                )
            case .refreshFailure(let failure):
                RefreshFailureOutputDetails(failure: failure)
            }
        }
        .alert(
            "Unable to Prepare Package Action",
            isPresented: $isShowingOperationPreparationError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(operationPreparationErrorMessage)
        }
    }

    private func refresh() {
        Task { await store.refresh() }
    }

    private func prepareOperation(
        for packageID: HomebrewPackage.ID,
        kind: HomebrewPackageOperationKind
    ) {
        do {
            operationReviewPresentation.present(
                try store.operationPlan(for: packageID, kind: kind)
            )
            openWindow(id: PackageOperationReviewPresentation.windowID)
            applicationPresentation.activate()
        } catch {
            operationPreparationErrorMessage = error.localizedDescription
            isShowingOperationPreparationError = true
        }
    }
}

private struct PresentedStatusMenuSheet: Identifiable {
    enum Content {
        case operationOutput(
            HomebrewPackageOperationOutput,
            followUpRefreshFailure: PackageStore.Failure?
        )
        case refreshFailure(PackageStore.Failure)
    }

    let id = UUID()
    let content: Content
}

#if DEBUG
#Preview("Installed packages") {
    StatusMenuView()
        .environment(
            PackageStore(
                state: .loaded(
                    HomebrewInventoryReport(
                        inventory: HomebrewInventory(
                            applications: [
                                HomebrewPackage(
                                    name: "visual-studio-code",
                                    versions: HomebrewPackageVersions(
                                        installed: ["1.104.0"],
                                        available: "1.105.0"
                                    ),
                                    kind: .cask,
                                    upgradeEligibility: HomebrewPackageUpgradeEligibility()
                                )
                            ],
                            formulae: [
                                HomebrewPackage(
                                    name: "swiftlint",
                                    versions: HomebrewPackageVersions(installed: ["0.59.1"]),
                                    kind: .formula
                                ),
                                HomebrewPackage(
                                    name: "wget",
                                    versions: HomebrewPackageVersions(installed: ["1.25.0"]),
                                    kind: .formula
                                )
                            ]
                        ),
                        commandResults: [],
                        refreshedAt: .now.addingTimeInterval(-120),
                        homebrewVersion: "5.0.0"
                    )
                ),
                homebrewService: HomebrewService(
                    executableURL: URL(
                        fileURLWithPath: "/opt/homebrew/bin/brew"
                    )
                )
            )
        )
        .environment(ApplicationPresentationController())
        .environment(PackageOperationReviewPresentation())
}
#endif
