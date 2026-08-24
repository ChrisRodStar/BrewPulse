import SwiftUI

struct PackageOperationCommandPreview: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(PackageStore.self) private var store
    @State private var confirmationErrorMessage = ""
    @State private var isShowingConfirmationError = false

    let plan: HomebrewOperationPlan

    var body: some View {
        let presentation = PackageOperationPresentation(kind: plan.kind)
        let commandText = CommandTextFormatter().string(for: plan.command)

        VStack(alignment: .leading, spacing: 16) {
            Label(presentation.reviewTitle(plan: plan), systemImage: "terminal")
                .font(.title2.bold())

            Text(presentation.reviewMessage(plan: plan))

            if let package = plan.package {
                PackageVersionSummary(
                    package: package,
                    showsAvailableVersion: plan.kind == .update
                )
            } else {
                UpdateAllPackageSummary(packages: plan.packages)
            }

            GroupBox("Exact Homebrew command") {
                ScrollView(.horizontal) {
                    Text(verbatim: commandText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Exact Homebrew command")
                .accessibilityValue(commandText)
            }

            Label("Nothing has run yet.", systemImage: "lock.shield")
                .font(.callout)
                .foregroundStyle(.secondary)

            PackageOperationNotice(plan: plan)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismissReviewWindow()
                }
                .keyboardShortcut(.cancelAction)

                confirmationButton(presentation: presentation)
            }
        }
        .padding(20)
        .frame(minWidth: 520, idealWidth: 560, minHeight: 270)
        .alert(
            presentation.confirmationErrorTitle,
            isPresented: $isShowingConfirmationError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(confirmationErrorMessage)
        }
    }

    @ViewBuilder
    private func confirmationButton(
        presentation: PackageOperationPresentation
    ) -> some View {
        if plan.kind == .uninstall {
            Button(presentation.confirmationTitle(plan: plan), role: .destructive) {
                confirmOperation()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityHint("Approves this exact Homebrew uninstall command.")
        } else {
            Button(presentation.confirmationTitle(plan: plan)) {
                confirmOperation()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .accessibilityHint("Approves this exact Homebrew update command.")
        }
    }

    private func confirmOperation() {
        do {
            try store.confirmOperation(plan)
            Task { await store.runConfirmedOperation() }
            dismissReviewWindow()
        } catch {
            confirmationErrorMessage = error.localizedDescription
            isShowingConfirmationError = true
        }
    }

    private func dismissReviewWindow() {
        dismissWindow(id: PackageOperationReviewPresentation.windowID)
    }
}

private struct PackageVersionSummary: View {
    let package: HomebrewPackage
    let showsAvailableVersion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ReviewVersionValue(
                title: "Installed",
                value: package.versions.installed.isEmpty
                    ? "Unknown"
                    : package.versions.installed.joined(separator: ", ")
            )
            if showsAvailableVersion,
               let availableVersion = package.versions.available {
                ReviewVersionValue(
                    title: "Available",
                    value: availableVersion
                )
            }
        }
        .monospacedDigit()
    }
}

private struct UpdateAllPackageSummary: View {
    let packages: [HomebrewPackage]

    var body: some View {
        GroupBox("Requested updates") {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 7) {
                    ForEach(packages) { package in
                        HStack(spacing: 8) {
                            Image(
                                systemName: package.kind == .cask
                                    ? "macwindow"
                                    : "shippingbox"
                            )
                            .foregroundStyle(CivicSignalTheme.brand)
                            .frame(width: 18)

                            Text(package.name)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let available = package.versions.available {
                                Text(available)
                                    .monospacedDigit()
                                    .foregroundStyle(CivicSignalTheme.secondaryText)
                            }
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 130)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ReviewVersionValue: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)
            Text(value)
                .lineLimit(3)
                .truncationMode(.middle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PackageOperationNotice: View {
    let plan: HomebrewOperationPlan

    var body: some View {
        switch (plan.kind, plan.package?.kind) {
        case (.update, .cask):
            Label(
                "This app update may open an installer or ask macOS for administrator approval.",
                systemImage: "person.badge.key"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        case (.uninstall, _):
            Label(
                "This standard uninstall does not use --zap or remove additional preference files.",
                systemImage: "trash.slash"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        case (.update, nil):
            Label(
                "Homebrew may also update required dependencies or repair dependents when it runs this command.",
                systemImage: "arrow.triangle.2.circlepath"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        case (.update, .formula):
            EmptyView()
        }
    }
}

nonisolated private struct PackageOperationPresentation {
    let kind: HomebrewPackageOperationKind

    func reviewTitle(plan: HomebrewOperationPlan) -> String {
        if plan.isUpdateAll { return "Review Update All" }
        return switch kind {
        case .update: "Review Update"
        case .uninstall: "Review Uninstall"
        }
    }

    func confirmationTitle(plan: HomebrewOperationPlan) -> String {
        if plan.isUpdateAll { return "Confirm All Updates" }
        return switch kind {
        case .update: "Confirm Update"
        case .uninstall: "Confirm Uninstall"
        }
    }

    var confirmationErrorTitle: String {
        switch kind {
        case .update: "Unable to Confirm Update"
        case .uninstall: "Unable to Confirm Uninstall"
        }
    }

    func reviewMessage(plan: HomebrewOperationPlan) -> String {
        if plan.isUpdateAll {
            return "Review the requested packages and exact Homebrew command before updating everything available."
        }
        let packageName = plan.package?.name ?? "this package"
        return switch kind {
        case .update:
            "Review this command before approving the update for \(packageName)."
        case .uninstall:
            "Review this command before removing \(packageName) from this Mac."
        }
    }
}

#if DEBUG
#Preview("Uninstall command preview") {
    let package = HomebrewPackage(
        name: "visual-studio-code",
        versions: HomebrewPackageVersions(installed: ["1.105.0"]),
        kind: .cask
    )
    let executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")

    PackageOperationCommandPreview(
        plan: .package(
            HomebrewPackageOperationPlan(
                kind: .uninstall,
                package: package,
                command: CommandRequest(
                    executableURL: executableURL,
                    arguments: ["uninstall", "--cask", "--", package.name]
                )
            )
        )
    )
    .environment(
        PackageStore(
            state: .loaded(
                HomebrewInventoryReport(
                    inventory: HomebrewInventory(
                        applications: [package],
                        formulae: []
                    ),
                    commandResults: [],
                    refreshedAt: .now
                )
            ),
            homebrewService: HomebrewService(executableURL: executableURL)
        )
    )
}
#endif
