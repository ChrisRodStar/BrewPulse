import Foundation

struct HomebrewInventory: Equatable, Sendable {
    let applications: [HomebrewPackage]
    let formulae: [HomebrewPackage]

    var count: Int { applications.count + formulae.count }
    var isEmpty: Bool { applications.isEmpty && formulae.isEmpty }
    var availableUpdateCount: Int {
        applications.count(where: hasAvailableUpdate)
            + formulae.count(where: hasAvailableUpdate)
    }

    func package(withID id: HomebrewPackage.ID) -> HomebrewPackage? {
        let packages = switch id.kind {
        case .cask:
            applications
        case .formula:
            formulae
        }

        return packages.first { $0.id == id }
    }

    private func hasAvailableUpdate(_ package: HomebrewPackage) -> Bool {
        package.versions.available != nil
    }
}
