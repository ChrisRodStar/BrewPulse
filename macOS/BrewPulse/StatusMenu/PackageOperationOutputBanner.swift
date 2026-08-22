import SwiftUI

struct PackageOperationOutputBanner: View {
    let output: HomebrewPackageOperationOutput
    let followUpRefreshFailure: PackageStore.Failure?
    let onViewDetails: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(output.plan.package.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if followUpRefreshFailure != nil {
                    Text("Package list refresh failed; older results remain visible")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Button("View Output", action: onViewDetails)
                .controlSize(.small)
                .accessibilityHint("Opens the Homebrew command output and exit status.")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var title: String {
        switch (output.plan.kind, output.status) {
        case (.update, .succeeded): "Updated successfully"
        case (.update, .failed): "Update failed"
        case (.update, .cancelled): "Update cancelled"
        case (.uninstall, .succeeded): "Uninstalled successfully"
        case (.uninstall, .failed): "Uninstall failed"
        case (.uninstall, .cancelled): "Uninstall cancelled"
        }
    }

    private var systemImage: String {
        switch output.status {
        case .succeeded: "checkmark.circle.fill"
        case .failed: "xmark.octagon.fill"
        case .cancelled: "stop.circle.fill"
        }
    }

    private var tint: Color {
        switch output.status {
        case .succeeded: .green
        case .failed: .red
        case .cancelled: .orange
        }
    }

    private var accessibilityLabel: String {
        let operationLabel = "\(title): \(output.plan.package.name)"
        guard followUpRefreshFailure != nil else { return operationLabel }
        return operationLabel
            + ". Package list refresh failed; older results remain visible."
    }
}

#if DEBUG
#Preview("Failed package action") {
    PackageOperationOutputBanner(
        output: .failedPreview,
        followUpRefreshFailure: nil,
        onViewDetails: {}
    )
    .frame(width: 400)
}

#Preview("Cancelled package action") {
    PackageOperationOutputBanner(
        output: .cancelledPreview,
        followUpRefreshFailure: nil,
        onViewDetails: {}
    )
    .frame(width: 400)
}
#endif
