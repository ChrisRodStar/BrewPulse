import SwiftUI

struct PackageUpdateButton: View {
    let packageName: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Update available", systemImage: "arrow.down.circle.fill")
                .font(.caption2.weight(.medium))
                .foregroundStyle(CivicSignalTheme.update)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(CivicSignalTheme.updateSurface, in: Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .disabled(isDisabled)
        .accessibilityLabel("Update \(packageName)")
        .accessibilityHint(
            isDisabled
                ? "Wait for the current Homebrew operation to finish."
                : "Shows the exact Homebrew command for review."
        )
        .help(
            isDisabled
                ? "Wait for the current Homebrew operation to finish"
                : "Update \(packageName)"
        )
    }
}
