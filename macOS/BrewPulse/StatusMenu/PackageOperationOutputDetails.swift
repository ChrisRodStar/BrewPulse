import AppKit
import SwiftUI

struct PackageOperationOutputDetails: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didCopyOutput = false

    let output: HomebrewPackageOperationOutput

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Homebrew Output", systemImage: "terminal")
                .font(.title2.bold())

            PackageOperationOutcomeSummary(output: output)

            PackageOperationCommandSummary(output: output)

            ForEach(output.guidance, id: \.self) { guidance in
                UpdateGuidanceNotice(guidance: guidance)
            }

            VStack(spacing: 12) {
                CommandOutputSection(
                    title: "Standard Output",
                    content: output.result?.standardOutput ?? "",
                    emptyMessage: "No standard output was captured."
                )
                CommandOutputSection(
                    title: "Standard Error",
                    content: output.result?.standardError ?? "",
                    emptyMessage: "No standard error was captured."
                )
            }

            HStack {
                Button {
                    copyOutput()
                } label: {
                    Label(
                        didCopyOutput ? "Copied" : "Copy Output",
                        systemImage: didCopyOutput ? "checkmark" : "doc.on.doc"
                    )
                }
                .disabled(output.textForCopying.isEmpty)
                .accessibilityHint(
                    output.textForCopying.isEmpty
                        ? "Homebrew did not produce output to copy."
                        : "Copies the preserved Homebrew command output."
                )
                .help(
                    output.textForCopying.isEmpty
                        ? "No Homebrew output to copy"
                        : "Copy Homebrew output"
                )

                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 620, idealWidth: 680, minHeight: 500)
    }

    private func copyOutput() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        didCopyOutput = pasteboard.setString(
            output.textForCopying,
            forType: .string
        )
    }
}

private struct PackageOperationOutcomeSummary: View {
    let output: HomebrewPackageOperationOutput

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch (output.plan.kind, output.status) {
        case (.update, .succeeded):
            "Updated \(output.plan.package.name)"
        case (.update, .failed):
            "Couldn’t update \(output.plan.package.name)"
        case (.update, .cancelled):
            "Cancelled \(output.plan.package.name) update"
        case (.uninstall, .succeeded):
            "Uninstalled \(output.plan.package.name)"
        case (.uninstall, .failed):
            "Couldn’t uninstall \(output.plan.package.name)"
        case (.uninstall, .cancelled):
            "Cancelled \(output.plan.package.name) uninstall"
        }
    }

    private var message: String {
        switch output.status {
        case .succeeded where output.plan.kind == .update:
            "Homebrew completed the update successfully."
        case .succeeded:
            "Homebrew completed the uninstall successfully."
        case .failed(let message):
            message
        case .cancelled:
            "Output produced before the interruption is preserved below."
        }
    }

    private var systemImage: String {
        switch output.status {
        case .succeeded:
            "checkmark.circle.fill"
        case .failed:
            "xmark.octagon.fill"
        case .cancelled:
            "stop.circle.fill"
        }
    }

    private var tint: Color {
        switch output.status {
        case .succeeded:
            .green
        case .failed:
            .red
        case .cancelled:
            .orange
        }
    }
}

private struct PackageOperationCommandSummary: View {
    let output: HomebrewPackageOperationOutput

    var body: some View {
        GroupBox("Command details") {
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal) {
                    Text(CommandTextFormatter().string(for: output.plan.command))
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: false)
                }

                if let result = output.result {
                    Divider()

                    HStack(spacing: 24) {
                        LabeledContent(
                            "Exit status",
                            value: String(result.terminationStatus)
                        )
                        LabeledContent("Started") {
                            Text(
                                result.startedAt,
                                format: .dateTime
                                    .year()
                                    .month()
                                    .day()
                                    .hour()
                                    .minute()
                                    .second()
                            )
                        }
                    }
                    .monospacedDigit()
                }
            }
            .padding(8)
        }
    }
}

private struct UpdateGuidanceNotice: View {
    let guidance: HomebrewCommandGuidance

    var body: some View {
        Label(message, systemImage: systemImage)
            .font(.callout)
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
    }

    private var message: String {
        switch guidance {
        case .administratorAccess:
            "Homebrew reported that administrator access or a password may be required. Check for a macOS prompt."
        case .externalInteraction:
            "Homebrew reported that another window needs your attention. Follow its instructions to finish."
        }
    }

    private var systemImage: String {
        switch guidance {
        case .administratorAccess:
            "person.badge.key"
        case .externalInteraction:
            "macwindow.badge.plus"
        }
    }
}

private struct CommandOutputSection: View {
    let title: String
    let content: String
    let emptyMessage: String

    var body: some View {
        GroupBox(title) {
            ScrollView([.horizontal, .vertical]) {
                Text(content.isEmpty ? emptyMessage : content)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(content.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(8)
            }
            .frame(maxWidth: .infinity, minHeight: 110, idealHeight: 140)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(content.isEmpty ? emptyMessage : content)
        }
    }
}

#if DEBUG
extension HomebrewPackageOperationOutput {
    static let preview: HomebrewPackageOperationOutput = {
        let package = HomebrewPackage(
            name: "visual-studio-code",
            versions: HomebrewPackageVersions(
                installed: ["1.104.0"],
                available: "1.105.0"
            ),
            kind: .cask,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
            arguments: ["upgrade", "--cask", "--", package.name]
        )
        return HomebrewPackageOperationOutput(
            plan: HomebrewPackageOperationPlan(
                kind: .update,
                package: package,
                command: request
            ),
            status: .succeeded,
            result: CommandResult(
                request: request,
                standardOutput: "==> Upgrading visual-studio-code\nUpgrade complete.\n",
                standardError: "",
                terminationStatus: 0,
                startedAt: .now,
                duration: .seconds(4)
            )
        )
    }()
}

#Preview("Homebrew output details") {
    PackageOperationOutputDetails(output: .preview)
}
#endif
