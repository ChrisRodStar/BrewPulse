import SwiftUI

nonisolated enum PackageUpdateStatus: Equatable, Sendable {
    case current
    case updateAvailable

    init(availableVersion: String?) {
        self = availableVersion == nil ? .current : .updateAvailable
    }

    var accessibilityDescription: String {
        switch self {
        case .current:
            "Up to date."
        case .updateAvailable:
            "Update available."
        }
    }
}

struct PackageStatusLabel: View {
    let status: PackageUpdateStatus

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
            .accessibilityHidden(true)
    }

    private var title: LocalizedStringKey {
        switch status {
        case .current:
            "Up to date"
        case .updateAvailable:
            "Update available"
        }
    }

    private var systemImage: String {
        switch status {
        case .current:
            "checkmark.circle.fill"
        case .updateAvailable:
            "arrow.down.circle.fill"
        }
    }

    private var color: Color {
        switch status {
        case .current:
            .gray
        case .updateAvailable:
            .orange
        }
    }
}
