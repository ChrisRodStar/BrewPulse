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
    @State private var selectedSection = StatusMenuSection.overview

    var body: some View {
        VStack(spacing: 0) {
            StatusMenuHeader(
                selection: $selectedSection,
                updateCount: store.state.report?.inventory.availableUpdateCount
            )
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
                selectedSection: $selectedSection,
                state: store.state,
                packageActionsDisabled: store.packageActionsDisabled,
                onRefresh: refresh,
                onShowRefreshFailureDetails: {
                    presentedSheet = PresentedStatusMenuSheet(
                        content: .refreshFailure($0)
                    )
                },
                onUpdate: { prepareOperation(for: $0, kind: .update) },
                onUpdateAll: prepareUpdateAll
            )
            Divider()
            HStack {
                Button {
                    refresh()
                } label: {
                    StatusMenuRefreshLabel(isRefreshing: store.state.isLoading)
                }
                .keyboardShortcut("r", modifiers: .command)
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
            .controlSize(.small)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(CivicSignalTheme.surface)
        }
        .frame(width: 400, height: 520)
        .background(CivicSignalTheme.canvas)
        .foregroundStyle(CivicSignalTheme.primaryText)
        .tint(CivicSignalTheme.brand)
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

    private func prepareUpdateAll() {
        do {
            operationReviewPresentation.present(
                try store.updateAllOperationPlan()
            )
            openWindow(id: PackageOperationReviewPresentation.windowID)
            applicationPresentation.activate()
        } catch {
            operationPreparationErrorMessage = error.localizedDescription
            isShowingOperationPreparationError = true
        }
    }
}

private struct StatusMenuRefreshLabel: View {
    let isRefreshing: Bool

    var body: some View {
        if isRefreshing {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.mini)

                Text("Refreshing…")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Refreshing package information")
        } else {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }
}

enum CivicSignalTheme {
    static let canvas = Color(
        nsColor: .civicSignal(light: 0xF5F6F4, dark: 0x111315)
    )
    static let surface = Color(
        nsColor: .civicSignal(light: 0xFFFFFF, dark: 0x1A1D21)
    )
    static let primaryText = Color(
        nsColor: .civicSignal(light: 0x111315, dark: 0xF5F6F4)
    )
    static let secondaryText = Color(
        nsColor: .civicSignal(light: 0x62686F, dark: 0xA8ADB3)
    )
    static let divider = Color(
        nsColor: .civicSignal(light: 0xD9DDDA, dark: 0x30343A)
    )
    static let brand = Color(
        nsColor: .civicSignal(light: 0x5E54F6, dark: 0x9B8CFF)
    )
    static let update = Color(
        nsColor: .civicSignal(light: 0x6B4300, dark: 0xFFD166)
    )
    static let updateSurface = Color(
        nsColor: .civicSignal(light: 0xFFF2D2, dark: 0x332B13)
    )
    static let updateStrong = Color(
        nsColor: .civicSignal(light: 0xF2B84B, dark: 0xD99B2B)
    )
    static let success = Color(
        nsColor: .civicSignal(light: 0x116B42, dark: 0x4BD591)
    )
    static let successSurface = Color(
        nsColor: .civicSignal(light: 0xE6F8EF, dark: 0x123324)
    )
    static let danger = Color(
        nsColor: .civicSignal(light: 0xB4233B, dark: 0xFF7A8C)
    )
    static let dangerSurface = Color(
        nsColor: .civicSignal(light: 0xFDECEF, dark: 0x3B171E)
    )
}

private extension NSColor {
    static func civicSignal(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let value = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? dark
                : light
            return NSColor(
                srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
                green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255,
                alpha: 1
            )
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
#Preview("Overview") {
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
