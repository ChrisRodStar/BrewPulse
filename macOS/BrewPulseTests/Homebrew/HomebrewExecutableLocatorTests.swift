import Foundation
import Testing
@testable import BrewPulse

@Suite("Homebrew executable locator")
struct HomebrewExecutableLocatorTests {
    @Test("Prefers the Apple Silicon installation path")
    func locatesAppleSiliconHomebrew() {
        let locator = locator(executablePaths: [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew"
        ])

        #expect(locator.locate() == URL(fileURLWithPath: "/opt/homebrew/bin/brew"))
    }

    @Test("Falls back to the Intel installation path")
    func locatesIntelHomebrew() {
        let locator = locator(executablePaths: [
            "/usr/local/bin/brew"
        ])

        #expect(locator.locate() == URL(fileURLWithPath: "/usr/local/bin/brew"))
    }

    private func locator(executablePaths: Set<String>) -> HomebrewExecutableLocator {
        HomebrewExecutableLocator { path in
            executablePaths.contains(path)
        }
    }
}
