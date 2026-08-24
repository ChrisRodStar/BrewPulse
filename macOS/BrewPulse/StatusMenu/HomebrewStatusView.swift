import SwiftUI

struct HomebrewStatusView: View {
    let report: HomebrewInventoryReport
    let onViewUpdates: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    OverviewStatusCanvas(
                        updateCount: report.inventory.availableUpdateCount,
                        installedCount: report.inventory.count,
                        homebrewVersion: report.homebrewVersion ?? "Unavailable",
                        refreshedAt: report.refreshedAt,
                        onViewUpdates: onViewUpdates
                    )

                    Label(
                        "Nothing runs without confirmation.",
                        systemImage: "checkmark.shield"
                    )
                    .font(.caption)
                    .foregroundStyle(CivicSignalTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(
                    minHeight: max(0, proxy.size.height - 32),
                    alignment: .top
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.never)
        }
    }
}

private struct OverviewStatusCanvas: View {
    let updateCount: Int
    let installedCount: Int
    let homebrewVersion: String
    let refreshedAt: Date
    let onViewUpdates: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var installedCountSize = 54

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: statusSymbol)
                    .font(.title2.weight(.bold))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.bold))

                    Text(message)
                        .font(.callout)
                        .opacity(0.78)
                }

                Spacer(minLength: 8)

                if updateCount > 0 {
                    Button("View Updates", action: onViewUpdates)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(foregroundColor)
                        .accessibilityHint("Shows packages that BrewPulse can update.")
                }
            }

            Spacer(minLength: 32)

            VStack(alignment: .leading, spacing: 0) {
                Text(installedCount.formatted())
                    .font(.system(size: installedCountSize, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("packages installed")
                    .font(.headline)
                    .opacity(0.76)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 24)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    homebrewVersionLabel

                    Spacer(minLength: 12)

                    refreshedLabel
                }

                VStack(alignment: .leading, spacing: 8) {
                    homebrewVersionLabel
                    refreshedLabel
                }
            }
            .font(.caption.weight(.medium))
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 304, alignment: .leading)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .contain)
    }

    private var homebrewVersionLabel: some View {
        Label {
            Text("Homebrew \(homebrewVersion)")
                .monospacedDigit()
        } icon: {
            Image(systemName: "terminal")
        }
    }

    private var refreshedLabel: some View {
        Label {
            Text("Checked \(refreshedAt, style: .relative)")
        } icon: {
            Image(systemName: "clock")
        }
    }

    private var statusSymbol: String {
        updateCount == 0 ? "checkmark.circle.fill" : "arrow.down.circle.fill"
    }

    private var title: String {
        switch updateCount {
        case 0:
            "Everything is up to date"
        case 1:
            "1 update available"
        default:
            "\(updateCount) updates available"
        }
    }

    private var message: String {
        updateCount == 0
            ? "Your Homebrew packages are current."
            : "Review one update or approve them all."
    }

    private var foregroundColor: Color {
        updateCount == 0 ? CivicSignalTheme.success : CivicSignalTheme.primaryText
    }

    private var backgroundColor: Color {
        updateCount == 0 ? CivicSignalTheme.successSurface : CivicSignalTheme.updateStrong
    }
}
