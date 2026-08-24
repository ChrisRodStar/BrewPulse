import SwiftUI

struct BrewPulseMenuBarLabel: View {
    let updateCount: Int?

    var body: some View {
        let presentation = BrewPulseMenuBarLabelPresentation(
            updateCount: updateCount
        )

        Image("BrewPulseMenuBarMark")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: 13, height: 13)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(presentation.accessibilityLabel)
            .help(presentation.accessibilityLabel)
    }
}

nonisolated struct BrewPulseMenuBarLabelPresentation: Equatable, Sendable {
    let accessibilityLabel: String

    init(updateCount: Int?) {
        switch updateCount {
        case nil:
            accessibilityLabel = "BrewPulse"
        case 0:
            accessibilityLabel = "BrewPulse, no updates available"
        case 1:
            accessibilityLabel = "BrewPulse, 1 update available"
        case let count?:
            accessibilityLabel = "BrewPulse, \(count) updates available"
        }
    }
}

#if DEBUG
#Preview("Menu bar labels") {
    VStack(alignment: .leading) {
        BrewPulseMenuBarLabel(updateCount: nil)
        BrewPulseMenuBarLabel(updateCount: 0)
        BrewPulseMenuBarLabel(updateCount: 3)
    }
    .padding()
}
#endif
