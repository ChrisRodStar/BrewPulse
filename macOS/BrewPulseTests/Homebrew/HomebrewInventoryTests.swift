import Testing
@testable import BrewPulse

@Suite("Homebrew inventory")
struct HomebrewInventoryTests {
    @Test("Counts available updates across formulae and casks")
    func countsAvailableUpdates() {
        let inventory = HomebrewInventory(
            applications: [
                package("current-app", available: nil, kind: .cask),
                package("outdated-app", available: "2.0", kind: .cask)
            ],
            formulae: [
                package("outdated-tool", available: "3.0", kind: .formula)
            ]
        )

        #expect(inventory.availableUpdateCount == 2)
    }

    private func package(
        _ name: String,
        available: String?,
        kind: HomebrewPackage.Kind
    ) -> HomebrewPackage {
        HomebrewPackage(
            name: name,
            versions: HomebrewPackageVersions(
                installed: ["1.0"],
                available: available
            ),
            kind: kind
        )
    }
}
