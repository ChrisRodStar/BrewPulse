import Testing
@testable import BrewPulse

@Suite("Homebrew package-list parser")
struct HomebrewPackageListParserTests {
    private let parser = HomebrewPackageListParser()

    @Test("Parses and sorts formulae while preserving each installed version")
    func parsesFormulae() throws {
        let output = try FixtureLoader.text(named: "formulae")

        let packages = parser.parse(output, kind: .formula)

        #expect(packages == [
            package("git", installed: ["2.50.1"], kind: .formula),
            package("local-tool", installed: [], kind: .formula),
            package("openssl@3", installed: ["3.5.2", "3.5.3"], kind: .formula),
            package("python@3.13", installed: ["3.13.7"], kind: .formula),
            package("zlib", installed: ["1.3.1"], kind: .formula)
        ])
    }

    @Test("Parses casks with their package kind")
    func parsesCasks() throws {
        let output = try FixtureLoader.text(named: "casks")

        let packages = parser.parse(output, kind: .cask)

        #expect(packages == [
            package("1password", installed: ["8.11.4"], kind: .cask),
            package("font-fira-code", installed: ["6.2"], kind: .cask),
            package("visual-studio-code", installed: ["1.103.1"], kind: .cask)
        ])
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
}
