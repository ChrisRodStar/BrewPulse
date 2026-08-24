import SwiftUI

struct PackageRow: View {
    let package: HomebrewPackage
    let actionsDisabled: Bool
    let onUpdate: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        let versions = PackageVersionPresentation(package.versions)
        let status = PackageUpdateStatus(
            availableVersion: versions.availableValue
        )
        let accessibilityValue = status.accessibilityDescription
            + " "
            + versions.accessibilityValue

        PackageSummary(
            package: package,
            versions: versions,
            status: status,
            accessibilityValue: accessibilityValue,
            actionsDisabled: actionsDisabled,
            onUpdate: onUpdate,
            onUninstall: onUninstall
        )
    }
}

private struct PackageSummary: View {
    let package: HomebrewPackage
    let versions: PackageVersionPresentation
    let status: PackageUpdateStatus
    let accessibilityValue: String
    let actionsDisabled: Bool
    let onUpdate: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: package.kind == .cask ? "app.dashed" : "shippingbox")
                .foregroundStyle(CivicSignalTheme.brand)
                .frame(width: 18)
                .padding(.top, 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(package.name)
                    .lineLimit(1)
                    .truncationMode(.middle)

                VStack(alignment: .leading, spacing: 2) {
                    PackageVersionValue(
                        title: "Installed",
                        value: versions.installedValue
                    )
                    if let availableValue = versions.availableValue {
                        PackageVersionValue(
                            title: "Available",
                            value: availableValue
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(CivicSignalTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(package.name)
            .accessibilityValue(accessibilityValue)
            .help("\(package.name)\n\(accessibilityValue)")

            if package.isStandardUpgradeAvailable {
                PackageUpdateButton(
                    packageName: package.name,
                    isDisabled: actionsDisabled,
                    action: onUpdate
                )
            } else {
                PackageStatusLabel(status: status)
            }

            PackageActionsMenu(
                packageName: package.name,
                isDisabled: actionsDisabled,
                onUninstall: onUninstall
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PackageActionsMenu: View {
    let packageName: String
    let isDisabled: Bool
    let onUninstall: () -> Void

    var body: some View {
        Menu {
            Button("Uninstall…", systemImage: "trash", role: .destructive) {
                onUninstall()
            }
            .accessibilityHint(
                "Reviews the exact Homebrew uninstall command before anything runs."
            )
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(isDisabled)
        .accessibilityLabel("More actions for \(packageName)")
        .help("More actions for \(packageName)")
    }
}

private struct PackageVersionValue: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(title)
                .fixedSize(horizontal: true, vertical: false)
            Text(value)
                .monospacedDigit()
                .lineLimit(2)
                .truncationMode(.middle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

nonisolated struct PackageVersionPresentation: Equatable, Sendable {
    let installedValue: String
    let availableValue: String?
    let accessibilityValue: String

    init(_ versions: HomebrewPackageVersions) {
        installedValue = versions.installed.isEmpty
            ? "Unknown"
            : versions.installed.joined(separator: ", ")
        availableValue = versions.available

        let installedDescription: String
        switch versions.installed.count {
        case 0:
            installedDescription = "Installed version unknown."
        case 1:
            installedDescription = "Installed version \(installedValue)."
        default:
            installedDescription = "Installed versions \(installedValue)."
        }

        if let availableValue {
            accessibilityValue = "\(installedDescription) Available version \(availableValue)."
        } else {
            accessibilityValue = installedDescription
        }
    }
}

#if DEBUG
#Preview("Package versions") {
    VStack(alignment: .leading) {
        PackageRow(
            package: HomebrewPackage(
                name: "visual-studio-code",
                versions: HomebrewPackageVersions(
                    installed: ["1.104.0"],
                    available: "1.105.0"
                ),
                kind: .cask,
                upgradeEligibility: HomebrewPackageUpgradeEligibility()
            ),
            actionsDisabled: false,
            onUpdate: {},
            onUninstall: {}
        )
        PackageRow(
            package: HomebrewPackage(
                name: "openssl@3",
                versions: HomebrewPackageVersions(
                    installed: ["3.5.2", "3.5.3"]
                ),
                kind: .formula
            ),
            actionsDisabled: false,
            onUpdate: {},
            onUninstall: {}
        )
    }
    .padding()
    .frame(width: 340)
}

#Preview("Long and multi-line versions") {
    PackageRow(
        package: HomebrewPackage(
            name: "package-with-a-long-name-that-keeps-row-actions-visible",
            versions: HomebrewPackageVersions(
                installed: [
                    "2026.08.21-build.1234567890",
                    "2026.08.22-release-candidate.2"
                ],
                available: "2026.09.01-release-candidate-with-a-long-suffix"
            ),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        ),
        actionsDisabled: false,
        onUpdate: {},
        onUninstall: {}
    )
    .padding()
    .frame(width: 340)
}

#Preview("Accessibility text size") {
    PackageRow(
        package: HomebrewPackage(
            name: "visual-studio-code",
            versions: HomebrewPackageVersions(
                installed: ["1.104.0", "1.104.1"],
                available: "1.105.0"
            ),
            kind: .cask,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        ),
        actionsDisabled: false,
        onUpdate: {},
        onUninstall: {}
    )
    .environment(\.dynamicTypeSize, .accessibility3)
    .padding()
    .frame(width: 400)
}
#endif
