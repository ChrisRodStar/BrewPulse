import Foundation

nonisolated enum PackageInventoryCategory: CaseIterable, Hashable, Identifiable,
    Sendable
{
    case casks
    case formulae

    var id: Self { self }

    var title: String {
        switch self {
        case .casks:
            "Casks"
        case .formulae:
            "Formulae"
        }
    }

    var systemImage: String {
        switch self {
        case .casks:
            "macwindow"
        case .formulae:
            "shippingbox"
        }
    }

    func packages(in inventory: HomebrewInventory) -> [HomebrewPackage] {
        switch self {
        case .casks:
            inventory.applications
        case .formulae:
            inventory.formulae
        }
    }

    func count(in inventory: HomebrewInventory) -> Int {
        packages(in: inventory).count
    }
}
