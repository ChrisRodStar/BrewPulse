import Testing
@testable import BrewPulse

@Suite("Homebrew inventory merger")
struct HomebrewInventoryMergerTests {
    @Test("Merges updates and eligibility by package kind and name")
    func mergesByStableIdentity() throws {
        let inventory = HomebrewInventory(
            applications: [package("shared", installed: ["1.0"], kind: .cask)],
            formulae: [
                package("widget", installed: ["1.0", "1.1"], kind: .formula),
                package("current-tool", installed: ["4.0"], kind: .formula),
                package("missing-metadata", installed: ["5.0"], kind: .formula)
            ]
        )
        let outdatedPackages = [
            outdatedPackage(
                "custom/tools/widget",
                available: "2.0",
                kind: .formula,
                blockers: [.pinned(version: "1.1")]
            ),
            outdatedPackage("shared", available: "3.0", kind: .cask),
            outdatedPackage("orphan", available: "9.0", kind: .formula)
        ]
        let packageMetadata = [
            metadata(
                "custom/tools/widget",
                inventoryName: "widget",
                kind: .formula,
                blockers: [.pinned(version: nil), .disabled]
            ),
            metadata("shared", kind: .cask, blockers: [.autoUpdates]),
            metadata("current-tool", kind: .formula)
        ]

        let merged = HomebrewInventoryMerger().merge(
            inventory: inventory,
            outdatedPackages: outdatedPackages,
            packageMetadata: packageMetadata
        )

        let application = try #require(merged.applications.first)
        #expect(application.versions.installed == ["1.0"])
        #expect(application.versions.available == "3.0")
        #expect(application.upgradeEligibility.blockers == [.autoUpdates])

        let formula = try #require(merged.formulae.first)
        #expect(formula.name == "custom/tools/widget")
        #expect(formula.versions.installed == ["1.0", "1.1"])
        #expect(formula.versions.available == "2.0")
        #expect(formula.upgradeEligibility.blockers == [
            .pinned(version: "1.1"),
            .disabled
        ])

        #expect(merged.formulae[1].versions.available == nil)
        #expect(merged.formulae[1].upgradeEligibility.allowsStandardUpgrade)
        #expect(merged.formulae[2].upgradeEligibility.blockers == [
            .metadataUnavailable
        ])
        #expect(merged.count == inventory.count)
    }

    private func package(
        _ name: String,
        installed: [String],
        kind: HomebrewPackage.Kind
    ) -> HomebrewPackage {
        HomebrewPackage(
            name: name,
            versions: HomebrewPackageVersions(installed: installed),
            kind: kind
        )
    }

    private func outdatedPackage(
        _ name: String,
        available: String,
        kind: HomebrewPackage.Kind,
        blockers: Set<HomebrewPackageUpgradeEligibility.Blocker> = []
    ) -> HomebrewOutdatedPackage {
        HomebrewOutdatedPackage(
            name: name,
            versions: HomebrewPackageVersions(
                installed: [],
                available: available
            ),
            kind: kind,
            upgradeEligibility: HomebrewPackageUpgradeEligibility(blockers: blockers)
        )
    }

    private func metadata(
        _ name: String,
        inventoryName: String? = nil,
        kind: HomebrewPackage.Kind,
        blockers: Set<HomebrewPackageUpgradeEligibility.Blocker> = []
    ) -> HomebrewPackageMetadata {
        HomebrewPackageMetadata(
            name: name,
            inventoryName: inventoryName,
            kind: kind,
            upgradeEligibility: HomebrewPackageUpgradeEligibility(blockers: blockers)
        )
    }
}
