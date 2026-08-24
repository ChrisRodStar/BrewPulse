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
        #expect(inventory.actionableUpdates.map(\.name) == [
            "outdated-tool",
            "outdated-app"
        ])
    }

    @Test("Excludes packages BrewPulse cannot update safely")
    func excludesBlockedUpdates() {
        let blockers: [HomebrewPackageUpgradeEligibility.Blocker] = [
            .pinned(version: "1.0"),
            .autoUpdates,
            .latestVersion,
            .disabled,
            .unavailable,
            .metadataUnavailable
        ]
        let inventory = HomebrewInventory(
            applications: blockers.enumerated().map { index, blocker in
                package(
                    "blocked-\(index)",
                    available: "2.0",
                    kind: .cask,
                    blockers: [blocker]
                )
            },
            formulae: [package("git", available: "2.0", kind: .formula)]
        )

        #expect(inventory.availableUpdateCount == 1)
        #expect(inventory.actionableUpdates.map(\.name) == ["git"])
    }

    private func package(
        _ name: String,
        available: String?,
        kind: HomebrewPackage.Kind,
        blockers: Set<HomebrewPackageUpgradeEligibility.Blocker> = []
    ) -> HomebrewPackage {
        HomebrewPackage(
            name: name,
            versions: HomebrewPackageVersions(
                installed: ["1.0"],
                available: available
            ),
            kind: kind,
            upgradeEligibility: HomebrewPackageUpgradeEligibility(
                blockers: blockers
            )
        )
    }
}
