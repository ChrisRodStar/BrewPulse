import Testing
@testable import BrewPulse

@Suite("Homebrew package")
struct HomebrewPackageTests {
    @Test("Keeps installed and available versions independent")
    func modelsVersionsSeparately() {
        let package = HomebrewPackage(
            name: "openssl@3",
            versions: HomebrewPackageVersions(
                installed: ["3.5.2", "3.5.3"],
                available: "3.5.4"
            ),
            kind: .formula
        )

        #expect(package.versions.installed == ["3.5.2", "3.5.3"])
        #expect(package.versions.available == "3.5.4")
    }

    @Test("Allows a standard upgrade only when an eligible update exists")
    func determinesStandardUpgradeAvailability() {
        let eligiblePackage = HomebrewPackage(
            name: "git",
            versions: HomebrewPackageVersions(
                installed: ["2.49.0"],
                available: "2.50.1"
            ),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )
        let currentPackage = HomebrewPackage(
            name: "wget",
            versions: HomebrewPackageVersions(installed: ["1.25.0"]),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility()
        )
        let pinnedPackage = HomebrewPackage(
            name: "openssl@3",
            versions: HomebrewPackageVersions(
                installed: ["3.5.2"],
                available: "3.5.4"
            ),
            kind: .formula,
            upgradeEligibility: HomebrewPackageUpgradeEligibility(
                blockers: [.pinned(version: "3.5.2")]
            )
        )

        #expect(eligiblePackage.isStandardUpgradeAvailable)
        #expect(!currentPackage.isStandardUpgradeAvailable)
        #expect(!pinnedPackage.isStandardUpgradeAvailable)
    }
}
