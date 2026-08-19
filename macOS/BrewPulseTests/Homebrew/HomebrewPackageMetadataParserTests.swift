import Testing
@testable import BrewPulse

@Suite("Homebrew package-metadata parser")
struct HomebrewPackageMetadataParserTests {
    @Test("Classifies upgrade blockers from installed package metadata")
    func classifiesUpgradeBlockers() throws {
        let output = try FixtureLoader.text(
            named: "installed-metadata",
            fileExtension: "json"
        )

        let data = try HomebrewPackageMetadataParser().parse(output)
        let git = try #require(package(named: "git", kind: .formula, in: data))
        let widget = try #require(
            package(named: "custom/tools/widget", kind: .formula, in: data)
        )
        let legacyTool = try #require(
            package(named: "legacy-tool", kind: .formula, in: data)
        )
        let visualStudioCode = try #require(
            package(named: "visual-studio-code", kind: .cask, in: data)
        )
        let rollingApp = try #require(
            package(named: "rolling-app", kind: .cask, in: data)
        )
        let blockedApp = try #require(
            package(named: "blocked-app", kind: .cask, in: data)
        )
        let unavailableApp = try #require(
            package(named: "unavailable-app", kind: .cask, in: data)
        )

        #expect(git.upgradeEligibility.allowsStandardUpgrade)
        #expect(widget.inventoryName == "widget")
        #expect(widget.upgradeEligibility.blockers == [.pinned(version: nil)])
        #expect(legacyTool.upgradeEligibility.blockers == [.disabled])
        #expect(visualStudioCode.upgradeEligibility.blockers == [.autoUpdates])
        #expect(rollingApp.upgradeEligibility.blockers == [.latestVersion])
        #expect(blockedApp.upgradeEligibility.blockers == [
            .pinned(version: "1.0"),
            .autoUpdates,
            .disabled
        ])
        #expect(unavailableApp.upgradeEligibility.blockers == [.unavailable])
    }

    @Test("Rejects malformed installed package metadata")
    func rejectsMalformedMetadata() {
        #expect(throws: DecodingError.self) {
            try HomebrewPackageMetadataParser().parse("{not-json}")
        }
    }

    private func package(
        named name: String,
        kind: HomebrewPackage.Kind,
        in data: HomebrewPackageMetadataData
    ) -> HomebrewPackageMetadata? {
        data.packages.first { $0.name == name && $0.kind == kind }
    }
}
