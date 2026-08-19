import SwiftUI

struct StatusMenuSectionPicker: View {
    @Binding var selection: StatusMenuSection
    let inventory: HomebrewInventory

    var body: some View {
        Picker("BrewPulse section", selection: $selection) {
            ForEach(StatusMenuSection.allCases) { section in
                Label(label(for: section), systemImage: section.systemImage)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("BrewPulse section")
        .help("Switch between status, casks, and formulae")
    }

    private func label(for section: StatusMenuSection) -> String {
        switch section {
        case .status:
            section.title
        case .casks:
            "\(section.title) (\(inventory.applications.count))"
        case .formulae:
            "\(section.title) (\(inventory.formulae.count))"
        }
    }
}
