import SwiftUI

struct PackageOperationCommandPreview: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(PackageStore.self) private var store
    @State private var confirmationErrorMessage = ""
    @State private var isShowingConfirmationError = false

    let plan: HomebrewPackageOperationPlan

    var body: some View {
        let presentation = PackageOperationPresentation(kind: plan.kind)
        let commandText = CommandTextFormatter().string(for: plan.command)

        VStack(alignment: .leading, spacing: 16) {
            Label(presentation.reviewTitle, systemImage: "terminal")
                .font(.title2.bold())

            Text(presentation.reviewMessage(packageName: plan.package.name))

            PackageVersionSummary(
                package: plan.package,
                showsAvailableVersion: plan.kind == .update
            )

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
            Button(presentation.confirmationTitle, role: .destructive) {
                confirmOperation()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityHint("Approves this exact Homebrew uninstall command.")
        } else {
            Button(presentation.confirmationTitle) {
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
        HStack(spacing: 20) {
            LabeledContent(
                "Installed",
                value: package.versions.installed.joined(separator: ", ")
            )
            if showsAvailableVersion,
               let availableVersion = package.versions.available {
                LabeledContent("Available", value: availableVersion)
            }
        }
        .monospacedDigit()
    }
}

private struct PackageOperationNotice: View {
    let plan: HomebrewPackageOperationPlan

    var body: some View {
        switch plan.kind {
        case .update where plan.package.kind == .cask:
            Label(
                "This app update may open an installer or ask macOS for administrator approval.",
                systemImage: "person.badge.key"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        case .uninstall:
            Label(
                "This standard uninstall does not use --zap or remove additional preference files.",
                systemImage: "trash.slash"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        case .update:
            EmptyView()
        }
    }
}

nonisolated private struct PackageOperationPresentation {
    let kind: HomebrewPackageOperationKind

    var reviewTitle: String {
        switch kind {
        case .update: "Review Update"
        case .uninstall: "Review Uninstall"
        }
    }

    var confirmationTitle: String {
        switch kind {
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

    func reviewMessage(packageName: String) -> String {
        switch kind {
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
        plan: HomebrewPackageOperationPlan(
            kind: .uninstall,
            package: package,
            command: CommandRequest(
                executableURL: executableURL,
                arguments: ["uninstall", "--cask", "--", package.name]
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
