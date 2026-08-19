import Testing
@testable import BrewPulse

@Suite("Homebrew version parser")
struct HomebrewVersionParserTests {
    @Test("Extracts the version from Homebrew's first output line")
    func extractsVersion() {
        let output = """
        Homebrew 5.0.0
        Homebrew/homebrew-core (git revision abc123; last commit 2026-08-18)
        """

        #expect(HomebrewVersionParser().parse(output) == "5.0.0")
    }

    @Test("Returns no version for empty output")
    func rejectsEmptyOutput() {
        #expect(HomebrewVersionParser().parse("\n  \n") == nil)
    }
}
