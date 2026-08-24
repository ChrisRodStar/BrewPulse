import SwiftUI

struct PackageInventoryList: View {
    let category: PackageInventoryCategory
    let packages: [HomebrewPackage]
    let packageActionsDisabled: Bool
    let onUpdate: (HomebrewPackage.ID) -> Void
    let onUninstall: (HomebrewPackage.ID) -> Void

    var body: some View {
        if packages.isEmpty {
            ContentUnavailableView(
                "No \(category.title)",
                systemImage: category.systemImage,
                description: Text(emptyDescription)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(packages) { package in
                    PackageRow(
                        package: package,
                        actionsDisabled: packageActionsDisabled,
                        onUpdate: { onUpdate(package.id) },
                        onUninstall: { onUninstall(package.id) }
                    )
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 12,
                            bottom: 8,
                            trailing: 12
                        )
                    )
                    .listRowBackground(CivicSignalTheme.canvas)
                    .listRowSeparatorTint(CivicSignalTheme.divider)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(CivicSignalTheme.canvas)
        }
    }

    private var emptyDescription: String {
        switch category {
        case .casks:
            "Graphical applications installed with Homebrew will appear here."
        case .formulae:
            "Command-line packages installed with Homebrew will appear here."
        }
    }
}

struct AvailableUpdatesList: View {
    let packages: [HomebrewPackage]
    let packageActionsDisabled: Bool
    let onUpdate: (HomebrewPackage.ID) -> Void
    let onUpdateAll: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !packages.isEmpty {
                HStack {
                    Text(updateCountTitle)
                        .font(.callout.weight(.semibold))

                    Spacer()

                    Button("Review All…", action: onUpdateAll)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(packageActionsDisabled)
                        .accessibilityHint(
                            "Shows the exact Homebrew command before updating every available package."
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(CivicSignalTheme.surface)

                Divider()
                    .overlay(CivicSignalTheme.divider)
            }

            if packages.isEmpty {
                ContentUnavailableView(
                    "No Updates Available",
                    systemImage: "checkmark.circle",
                    description: Text("Everything BrewPulse can update is current.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(packages) { package in
                    AvailableUpdateRow(
                        package: package,
                        isDisabled: packageActionsDisabled,
                        onReview: { onUpdate(package.id) }
                    )
                    .listRowInsets(
                        EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 14)
                    )
                    .listRowBackground(CivicSignalTheme.canvas)
                    .listRowSeparatorTint(CivicSignalTheme.divider)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(CivicSignalTheme.canvas)
            }
        }
    }

    private var updateCountTitle: String {
        switch packages.count {
        case 0:
            "Up to date"
        case 1:
            "1 available update"
        default:
            "\(packages.count) available updates"
        }
    }
}

private struct AvailableUpdateRow: View {
    let package: HomebrewPackage
    let isDisabled: Bool
    let onReview: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(CivicSignalTheme.update)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(package.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(versionChange)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(CivicSignalTheme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Button("Review…", action: onReview)
                .controlSize(.small)
                .disabled(isDisabled)
                .accessibilityLabel("Review update for \(package.name)")
                .accessibilityHint("Shows the exact Homebrew command before it runs.")
        }
        .accessibilityElement(children: .contain)
    }

    private var versionChange: String {
        let installed = package.versions.installed.isEmpty
            ? "Unknown"
            : package.versions.installed.joined(separator: ", ")
        let available = package.versions.available ?? "Unknown"
        return "\(installed) → \(available)"
    }
}
