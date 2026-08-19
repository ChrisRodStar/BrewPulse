import Testing
@testable import BrewPulse

@Suite("Package inventory categories")
struct PackageInventoryCategoryTests {
    @Test("Casks expose only application packages")
    func casks() {
        let inventory = makeInventory()

        #expect(
            PackageInventoryCategory.casks.packages(in: inventory)
                == inventory.applications
        )
        #expect(PackageInventoryCategory.casks.count(in: inventory) == 1)
    }

    @Test("Formulae expose only command-line packages")
    func formulae() {
        let inventory = makeInventory()

        #expect(
            PackageInventoryCategory.formulae.packages(in: inventory)
                == inventory.formulae
        )
        #expect(PackageInventoryCategory.formulae.count(in: inventory) == 2)
    }

    private func makeInventory() -> HomebrewInventory {
        HomebrewInventory(
            applications: [
                HomebrewPackage(
                    name: "visual-studio-code",
                    versions: HomebrewPackageVersions(installed: ["1.0"]),
                    kind: .cask
                )
            ],
            formulae: [
                HomebrewPackage(
                    name: "swiftlint",
                    versions: HomebrewPackageVersions(installed: ["1.0"]),
                    kind: .formula
                ),
                HomebrewPackage(
                    name: "wget",
                    versions: HomebrewPackageVersions(installed: ["1.0"]),
                    kind: .formula
                )
            ]
        )
    }
}
