import Foundation
import Testing
@testable import BrewPulse

@Suite("Homebrew outdated-data parser")
struct HomebrewOutdatedDataParserTests {
    @Test("Decodes packages with explicit kinds, versions, and pin metadata")
    func decodesOutdatedData() throws {
        let output = try FixtureLoader.text(
            named: "outdated",
            fileExtension: "json"
        )

        let data = try HomebrewOutdatedDataParser().parse(output)

        #expect(data.packages.map(\.name) == [
            "git",
            "custom/tools/widget",
            "visual-studio-code"
        ])
        #expect(data.packages.map(\.kind) == [.formula, .formula, .cask])
        #expect(data.packages.map(\.versions.installed) == [
            ["2.49.0"],
            ["1.0.0", "1.1.0"],
            ["1.104.0"]
        ])
        #expect(data.packages.map(\.versions.available) == [
            "2.50.1",
            "2.0.0",
            "1.105.0"
        ])
        #expect(data.packages[0].upgradeEligibility.allowsStandardUpgrade)
        #expect(data.packages[1].upgradeEligibility.blockers == [
            .pinned(version: "1.1.0")
        ])
        #expect(data.packages[2].upgradeEligibility.allowsStandardUpgrade)
    }

    @Test("Decodes an empty outdated result")
    func decodesEmptyOutdatedData() throws {
        let data = try HomebrewOutdatedDataParser().parse(
            #"{"formulae":[],"casks":[]}"#
        )

        #expect(data.packages.isEmpty)
    }

    @Test("Rejects malformed structured output")
    func rejectsMalformedOutput() {
        #expect(throws: DecodingError.self) {
            try HomebrewOutdatedDataParser().parse("{not-json}")
        }
    }
}
