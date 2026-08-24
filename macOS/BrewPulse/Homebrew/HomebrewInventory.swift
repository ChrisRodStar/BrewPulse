import Foundation

struct HomebrewInventory: Equatable, Sendable {
    let applications: [HomebrewPackage]
    let formulae: [HomebrewPackage]

    var count: Int { applications.count + formulae.count }
    var isEmpty: Bool { applications.isEmpty && formulae.isEmpty }
    var actionableUpdates: [HomebrewPackage] {
        (applications + formulae)
            .filter(\.isStandardUpgradeAvailable)
            .sorted { lhs, rhs in
                if lhs.kind == rhs.kind {
                    lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                } else {
                    lhs.kind == .formula
                }
            }
    }
    var availableUpdateCount: Int { actionableUpdates.count }

    func package(withID id: HomebrewPackage.ID) -> HomebrewPackage? {
        let packages = switch id.kind {
        case .cask:
            applications
        case .formula:
            formulae
        }

        return packages.first { $0.id == id }
    }
}
