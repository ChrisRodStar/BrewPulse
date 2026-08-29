import SwiftUI

struct BrewPulseMenuBarLabel: View {
    let updateCount: Int?
    let hasPendingAppUpdate: Bool

    init(updateCount: Int?, hasPendingAppUpdate: Bool = false) {
        self.updateCount = updateCount
        self.hasPendingAppUpdate = hasPendingAppUpdate
    }

    var body: some View {
        let presentation = BrewPulseMenuBarLabelPresentation(
            updateCount: updateCount,
            hasPendingAppUpdate: hasPendingAppUpdate
        )

        ZStack(alignment: .topTrailing) {
            Image("BrewPulseMenuBarMark")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 13, height: 13)

            if hasPendingAppUpdate {
                Circle()
                    .fill(.orange)
                    .frame(width: 5, height: 5)
                    .offset(x: 2, y: -2)
                    .accessibilityHidden(true)
            }
        }
        .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(presentation.accessibilityLabel)
            .help(presentation.accessibilityLabel)
    }
}

nonisolated struct BrewPulseMenuBarLabelPresentation: Equatable, Sendable {
    let accessibilityLabel: String

    init(updateCount: Int?, hasPendingAppUpdate: Bool = false) {
        let appUpdateSuffix = hasPendingAppUpdate ? ", BrewPulse update ready" : ""
        switch updateCount {
        case nil:
            accessibilityLabel = "BrewPulse\(appUpdateSuffix)"
        case 0:
            accessibilityLabel = "BrewPulse, no updates available\(appUpdateSuffix)"
        case 1:
            accessibilityLabel = "BrewPulse, 1 update available\(appUpdateSuffix)"
        case let count?:
            accessibilityLabel = "BrewPulse, \(count) updates available\(appUpdateSuffix)"
        }
    }
}

#if DEBUG
#Preview("Menu bar labels") {
    VStack(alignment: .leading) {
        BrewPulseMenuBarLabel(updateCount: nil)
        BrewPulseMenuBarLabel(updateCount: 0, hasPendingAppUpdate: true)
        BrewPulseMenuBarLabel(updateCount: 3)
    }
    .padding()
}
#endif
