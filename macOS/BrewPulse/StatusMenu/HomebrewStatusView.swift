import SwiftUI

struct HomebrewStatusView: View {
    let report: HomebrewInventoryReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HomebrewHealthCard(inventory: report.inventory)

                Text("Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 10) {
                    StatusMetricCard(
                        title: "Homebrew",
                        value: report.homebrewVersion ?? "Unavailable",
                        systemImage: "mug.fill"
                    )
                    StatusMetricCard(
                        title: "Installed",
                        value: report.inventory.count.formatted(),
                        systemImage: "square.stack.3d.up.fill"
                    )
                }

                HStack(spacing: 10) {
                    StatusMetricCard(
                        title: "Casks",
                        value: report.inventory.applications.count.formatted(),
                        systemImage: "macwindow"
                    )
                    StatusMetricCard(
                        title: "Formulae",
                        value: report.inventory.formulae.count.formatted(),
                        systemImage: "shippingbox.fill"
                    )
                }

                Label {
                    Text("Last checked \(report.refreshedAt, style: .relative)")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityElement(children: .combine)
            }
            .padding(16)
        }
    }
}

private struct HomebrewHealthCard: View {
    let inventory: HomebrewInventory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12), in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary.opacity(0.15), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch inventory.availableUpdateCount {
        case 0 where inventory.isEmpty:
            "Homebrew is ready"
        case 0:
            "Everything is up to date"
        case 1:
            "1 update available"
        default:
            "\(inventory.availableUpdateCount) updates available"
        }
    }

    private var description: String {
        if inventory.isEmpty {
            "No installed casks or formulae were found."
        } else if inventory.availableUpdateCount == 0 {
            "All \(inventory.count) installed packages are current."
        } else {
            "Review the package tabs to see what can be updated."
        }
    }

    private var systemImage: String {
        if inventory.isEmpty {
            "shippingbox"
        } else if inventory.availableUpdateCount == 0 {
            "checkmark.circle.fill"
        } else {
            "arrow.down.circle.fill"
        }
    }

    private var color: Color {
        if inventory.isEmpty {
            .secondary
        } else if inventory.availableUpdateCount == 0 {
            .green
        } else {
            .orange
        }
    }
}

private struct StatusMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }
}
