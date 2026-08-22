import SwiftUI

struct PackageOperationProgressBanner: View {
    let plan: HomebrewPackageOperationPlan
    let isCancelling: Bool
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text(progressTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(plan.package.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)

            Button(
                isCancelling ? "Cancelling…" : "Cancel",
                role: .cancel,
                action: onCancel
            )
            .controlSize(.small)
            .disabled(isCancelling)
            .accessibilityHint(
                "Asks Homebrew to stop and preserves output produced so far."
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(progressTitle): \(plan.package.name)")
    }

    private var progressTitle: String {
        if isCancelling {
            return "Cancelling operation…"
        }
        return switch plan.kind {
        case .update: "Updating"
        case .uninstall: "Uninstalling"
        }
    }
}

#if DEBUG
#Preview("Uninstall in progress") {
    let package = HomebrewPackage(
        name: "visual-studio-code",
        versions: HomebrewPackageVersions(installed: ["1.105.0"]),
        kind: .cask
    )
    PackageOperationProgressBanner(
        plan: HomebrewPackageOperationPlan(
            kind: .uninstall,
            package: package,
            command: CommandRequest(
                executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
                arguments: ["uninstall", "--cask", "--", package.name]
            )
        ),
        isCancelling: false,
        onCancel: {}
    )
    .frame(width: 360)
}
#endif
