import AppKit
import SwiftUI

struct InitialRefreshFailureView: View {
    let failure: PackageStore.Failure
    let onRefresh: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: failure.systemImage)
                    .font(.system(size: 34))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                Text(failure.title)
                    .font(.title3.bold())

                Text(failure.explanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if failure.kind == .homebrewNotInstalled {
                    MissingHomebrewRecovery(
                        searchedPaths: failure.searchedExecutablePaths
                    )
                }

                HStack(spacing: 10) {
                    if !failure.commandResults.isEmpty {
                        Button("Show Details", action: onShowDetails)
                    }

                    Button("Try Again", action: onRefresh)
                        .keyboardShortcut("r", modifiers: .command)
                }
            }
            .frame(maxWidth: 340)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
}

struct RefreshFailureBanner: View {
    let failure: PackageStore.Failure
    let retainedAt: Date
    let onShowDetails: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: failure.systemImage)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(failure.title)
                    .font(.callout.weight(.semibold))
                Text(failure.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(
                    "Showing the last complete snapshot from \(retainedAt.formatted(date: .abbreviated, time: .shortened))."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

                if !failure.commandResults.isEmpty {
                    Button("Show Details", action: onShowDetails)
                        .buttonStyle(.link)
                        .accessibilityHint("Shows the preserved Homebrew commands and output.")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.08))
    }
}

struct RefreshFailureOutputDetails: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didCopyOutput = false

    let failure: PackageStore.Failure
    private let commands: [PreservedRefreshCommand]

    init(failure: PackageStore.Failure) {
        self.failure = failure
        commands = failure.commandResults.enumerated().map {
            PreservedRefreshCommand(id: $0.offset, result: $0.element)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Refresh Failure Details", systemImage: "terminal")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 3) {
                Text(failure.title)
                    .font(.headline)
                Text(failure.explanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(commands) { command in
                        PreservedRefreshCommandDetails(command: command)
                    }
                }
            }

            HStack {
                Button {
                    copyOutput()
                } label: {
                    Label(
                        didCopyOutput ? "Copied" : "Copy All",
                        systemImage: didCopyOutput ? "checkmark" : "doc.on.doc"
                    )
                }
                .accessibilityHint("Copies every preserved command, exit status, and output.")
                .help("Copy all preserved refresh details")

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 620, idealWidth: 680, minHeight: 520)
    }

    private func copyOutput() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        didCopyOutput = pasteboard.setString(
            RefreshFailureOutputFormatter().string(
                for: failure.commandResults
            ),
            forType: .string
        )
    }
}

nonisolated struct RefreshFailureOutputFormatter: Sendable {
    func string(for results: [CommandResult]) -> String {
        results.enumerated().map { index, result in
            [
                "Refresh command \(index + 1)",
                "Exact command: \(CommandTextFormatter().string(for: result.request))",
                "Exit status: \(result.terminationStatus)",
                "Standard output:",
                result.standardOutput.isEmpty ? "<no output>" : result.standardOutput,
                "Standard error:",
                result.standardError.isEmpty ? "<no output>" : result.standardError
            ].joined(separator: "\n")
        }
        .joined(separator: "\n\n---\n\n")
    }
}

private struct MissingHomebrewRecovery: View {
    let searchedPaths: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BrewPulse checked these locations:")
                .font(.caption.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(searchedPaths, id: \.self) { path in
                    Text(path)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            Link(destination: URL(string: "https://brew.sh")!) {
                Label("Open Homebrew Installation Guide", systemImage: "arrow.up.right.square")
            }
            .accessibilityHint("Opens brew.sh. BrewPulse will not run an installer.")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
    }
}

private struct PreservedRefreshCommand: Identifiable {
    let id: Int
    let result: CommandResult
}

private struct PreservedRefreshCommandDetails: View {
    let command: PreservedRefreshCommand

    var body: some View {
        GroupBox("Command \(command.id + 1)") {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal) {
                    Text(CommandTextFormatter().string(for: command.result.request))
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: false)
                }

                LabeledContent(
                    "Exit status",
                    value: String(command.result.terminationStatus)
                )
                .monospacedDigit()

                RefreshCommandOutputSection(
                    title: "Standard Output",
                    content: command.result.standardOutput,
                    emptyMessage: "No standard output was captured."
                )
                RefreshCommandOutputSection(
                    title: "Standard Error",
                    content: command.result.standardError,
                    emptyMessage: "No standard error was captured."
                )
            }
            .padding(8)
        }
    }
}

private struct RefreshCommandOutputSection: View {
    let title: String
    let content: String
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView([.horizontal, .vertical]) {
                Text(content.isEmpty ? emptyMessage : content)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(content.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(8)
            }
            .frame(maxWidth: .infinity, minHeight: 90, idealHeight: 120)
            .background(.quaternary.opacity(0.25), in: .rect(cornerRadius: 6))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(content.isEmpty ? emptyMessage : content)
        }
    }
}

private extension PackageStore.Failure {
    var title: String {
        switch kind {
        case .homebrewNotInstalled:
            "Homebrew Not Found"
        case .connectivityFailure:
            "Homebrew Couldn’t Connect"
        case .commandTimedOut:
            "Homebrew Refresh Timed Out"
        case .commandFailed:
            "Homebrew Command Failed"
        case .unreadableOutdatedData,
             .unreadablePackageMetadata:
            "Homebrew Output Wasn’t Readable"
        case .unexpected:
            "Unable to Refresh Packages"
        }
    }

    var explanation: String {
        switch kind {
        case .homebrewNotInstalled:
            "Install or repair Homebrew, then try again. BrewPulse will only open the official guide; it will not run an installer."
        case .connectivityFailure:
            "Homebrew could not reach a required service. Check your connection, then try again."
        case .commandTimedOut:
            "Homebrew did not finish within five minutes. BrewPulse stopped the refresh safely."
        case .commandFailed:
            message
        case .unreadableOutdatedData:
            "Homebrew returned outdated-package data BrewPulse could not read. No partial package data was applied."
        case .unreadablePackageMetadata:
            "Homebrew returned package metadata BrewPulse could not read. No partial package data was applied."
        case .unexpected:
            message
        }
    }

    var systemImage: String {
        switch kind {
        case .homebrewNotInstalled:
            "mug"
        case .connectivityFailure:
            "network.slash"
        case .commandTimedOut:
            "clock.badge.exclamationmark"
        case .commandFailed,
             .unreadableOutdatedData,
             .unreadablePackageMetadata,
             .unexpected:
            "exclamationmark.triangle.fill"
        }
    }
}
