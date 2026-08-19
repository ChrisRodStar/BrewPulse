import Testing
@testable import BrewPulse

@Suite("Package update status")
struct PackageUpdateStatusTests {
    @Test("Treats a package without an available version as current")
    func currentPackage() {
        let status = PackageUpdateStatus(availableVersion: nil)

        #expect(status == .current)
        #expect(status.accessibilityDescription == "Up to date.")
    }

    @Test("Treats a package with an available version as outdated")
    func outdatedPackage() {
        let status = PackageUpdateStatus(availableVersion: "2.0")

        #expect(status == .updateAvailable)
        #expect(status.accessibilityDescription == "Update available.")
    }
}
