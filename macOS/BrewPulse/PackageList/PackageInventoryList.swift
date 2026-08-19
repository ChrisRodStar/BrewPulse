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
                }
            }
            .listStyle(.plain)
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
