import SwiftUI

struct StatusMenuSectionPicker: View {
    @Binding var selection: StatusMenuSection
    let updateCount: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedSection: StatusMenuSection?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(StatusMenuSection.allCases) { section in
                Button {
                    selection = section
                    focusedSection = section
                } label: {
                    Text(label(for: section))
                        .font(.callout.weight(selection == section ? .semibold : .medium))
                        .foregroundStyle(
                            selection == section
                                ? CivicSignalTheme.primaryText
                                : CivicSignalTheme.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                    .background {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(
                                selection == section
                                    ? CivicSignalTheme.surface
                                    : CivicSignalTheme.brand.opacity(
                                        focusedSection == section ? 0.09 : 0
                                    )
                            )
                            .shadow(
                                color: selection == section ? .black.opacity(0.1) : .clear,
                                radius: 1,
                                y: 1
                            )
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .focused($focusedSection, equals: section)
                .accessibilityLabel(label(for: section))
                .accessibilityAddTraits(selection == section ? .isSelected : [])
                .accessibilityHint("Switches the package view")
                .frame(maxWidth: .infinity)
            }
        }
        .padding(3)
        .background(
            CivicSignalTheme.canvas,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(CivicSignalTheme.divider.opacity(0.75), lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("BrewPulse section")
        .help("Switch between the overview and available updates")
        .onMoveCommand(perform: moveSelection)
        .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: selection)
    }

    private func label(for section: StatusMenuSection) -> String {
        switch section {
        case .overview:
            section.title
        case .updates:
            if let updateCount {
                "\(section.title) (\(updateCount))"
            } else {
                section.title
            }
        }
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        let sections = StatusMenuSection.allCases
        guard let currentIndex = sections.firstIndex(of: selection) else { return }

        let nextIndex: Int
        switch direction {
        case .left:
            nextIndex = max(sections.startIndex, currentIndex - 1)
        case .right:
            nextIndex = min(sections.index(before: sections.endIndex), currentIndex + 1)
        default:
            return
        }

        selection = sections[nextIndex]
        focusedSection = selection
    }
}
