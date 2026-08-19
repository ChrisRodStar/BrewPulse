import Testing
@testable import BrewPulse

@Suite("Package version presentation")
struct PackageVersionPresentationTests {
    @Test("Shows one installed version without an unavailable latest version")
    func currentPackage() {
        let presentation = PackageVersionPresentation(
            HomebrewPackageVersions(installed: ["1.0"])
        )

        #expect(presentation.installedValue == "1.0")
        #expect(presentation.availableValue == nil)
        #expect(presentation.accessibilityValue == "Installed version 1.0.")
    }

    @Test("Shows multiple installed versions and the available version")
    func outdatedPackageWithMultipleVersions() {
        let presentation = PackageVersionPresentation(
            HomebrewPackageVersions(
                installed: ["1.0", "1.1"],
                available: "2.0"
            )
        )

        #expect(presentation.installedValue == "1.0, 1.1")
        #expect(presentation.availableValue == "2.0")
        #expect(
            presentation.accessibilityValue
                == "Installed versions 1.0, 1.1. Available version 2.0."
        )
    }

    @Test("Handles missing installed version data")
    func unknownInstalledVersion() {
        let presentation = PackageVersionPresentation(
            HomebrewPackageVersions(installed: [], available: "2.0")
        )

        #expect(presentation.installedValue == "Unknown")
        #expect(
            presentation.accessibilityValue
                == "Installed version unknown. Available version 2.0."
        )
    }
}
