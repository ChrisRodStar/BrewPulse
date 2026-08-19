import SwiftUI

struct PackageOperationOutputBanner: View {
    let output: HomebrewPackageOperationOutput
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
            }

            Spacer(minLength: 0)

            Button("View Output", action: onViewDetails)
                .controlSize(.small)
                .accessibilityHint("Opens the Homebrew command output and exit status.")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title): \(output.plan.package.name)")
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
}
