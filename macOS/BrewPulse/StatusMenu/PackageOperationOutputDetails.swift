import AppKit
import SwiftUI

struct PackageOperationOutputDetails: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didCopyOutput = false

    let output: HomebrewPackageOperationOutput
    let followUpRefreshFailure: PackageStore.Failure?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Homebrew Output", systemImage: "terminal")
                .font(.title2.bold())

            PackageOperationOutcomeSummary(
                output: output,
                followUpRefreshFailed: followUpRefreshFailure != nil
            )

            if let followUpRefreshFailure {
                PackageOperationRefreshWarning(failure: followUpRefreshFailure)
            }

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
    let followUpRefreshFailed: Bool

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
        if output.plan.isUpdateAll {
            return switch output.status {
            case .succeeded: "Updates completed"
            case .failed: "Couldn’t update all packages"
            case .cancelled: "Cancelled Update All"
            }
        }
        let packageName = output.plan.package?.name ?? "package"
        return switch (output.plan.kind, output.status) {
        case (.update, .succeeded):
            "Updated \(packageName)"
        case (.update, .failed):
            "Couldn’t update \(packageName)"
        case (.update, .cancelled):
            "Cancelled \(packageName) update"
        case (.uninstall, .succeeded):
            "Uninstalled \(packageName)"
        case (.uninstall, .failed):
            "Couldn’t uninstall \(packageName)"
        case (.uninstall, .cancelled):
            "Cancelled \(packageName) uninstall"
        }
    }

    private var message: String {
        switch output.status {
        case .succeeded where followUpRefreshFailed:
            "Homebrew completed the package action, but BrewPulse could not verify the new package list."
        case .succeeded where output.plan.kind == .update:
            "Homebrew completed the update successfully, and BrewPulse refreshed the package list."
        case .succeeded:
            "Homebrew completed the uninstall successfully, and BrewPulse refreshed the package list."
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

private struct PackageOperationRefreshWarning: View {
    let failure: PackageStore.Failure

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text("Package list not refreshed")
                    .font(.headline)
                Text("The package action succeeded, but the inventory still shows the older snapshot. Refresh again before relying on package status.")
                    .font(.callout)
                Text(failure.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .accessibilityElement(children: .combine)
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
            CommandOutputTextView(
                text: content.isEmpty ? emptyMessage : content,
                usesSecondaryColor: content.isEmpty,
                accessibilityLabel: title
            )
            .frame(maxWidth: .infinity, minHeight: 110, idealHeight: 140)
        }
    }
}

private struct CommandOutputTextView: NSViewRepresentable {
    let text: String
    let usesSecondaryColor: Bool
    let accessibilityLabel: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = .monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false
        textView.setAccessibilityLabel(accessibilityLabel)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }
        if textView.string != text {
            textView.string = text
            textView.scrollToBeginningOfDocument(nil)
        }
        textView.textColor = usesSecondaryColor
            ? .secondaryLabelColor
            : .labelColor
        textView.setAccessibilityLabel(accessibilityLabel)
    }
}

#if DEBUG
extension HomebrewPackageOperationOutput {
    static let preview = preview(status: .succeeded)
    static let failedPreview = preview(
        status: .failed(message: "Homebrew could not replace the installed app.")
    )
    static let cancelledPreview = preview(status: .cancelled)

    private static func preview(
        status: HomebrewPackageOperationOutput.Status
    ) -> HomebrewPackageOperationOutput {
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
        let standardError: String
        let terminationStatus: Int32
        switch status {
        case .succeeded:
            standardError = ""
            terminationStatus = 0
        case .failed:
            standardError = "Error: installer returned a failure.\n"
            terminationStatus = 1
        case .cancelled:
            standardError = "Interrupted by user.\n"
            terminationStatus = 130
        }
        return HomebrewPackageOperationOutput(
            plan: .package(
                HomebrewPackageOperationPlan(
                    kind: .update,
                    package: package,
                    command: request
                )
            ),
            status: status,
            result: CommandResult(
                request: request,
                standardOutput: "==> Upgrading visual-studio-code\n",
                standardError: standardError,
                terminationStatus: terminationStatus,
                startedAt: .now,
                duration: .seconds(4)
            )
        )
    }
}

#Preview("Homebrew output details") {
    PackageOperationOutputDetails(
        output: .preview,
        followUpRefreshFailure: nil
    )
}
#Preview("Failed operation output") {
    PackageOperationOutputDetails(
        output: .failedPreview,
        followUpRefreshFailure: nil
    )
}

#Preview("Cancelled operation output") {
    PackageOperationOutputDetails(
        output: .cancelledPreview,
        followUpRefreshFailure: nil
    )
}
#endif
