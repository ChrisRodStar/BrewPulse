import SwiftUI

struct StatusMenuHeader: View {
    @Binding var selection: StatusMenuSection
    let updateCount: Int?

    var body: some View {
        HStack(spacing: 12) {
            Image("BrewPulseBrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .accessibilityLabel("BrewPulse")

            StatusMenuSectionPicker(
                selection: $selection,
                updateCount: updateCount
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(CivicSignalTheme.surface)
    }
}
