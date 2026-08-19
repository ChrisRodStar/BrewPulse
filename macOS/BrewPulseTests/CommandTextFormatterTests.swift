import Foundation
import Testing
@testable import BrewPulse

@Suite("Command text formatter")
struct CommandTextFormatterTests {
    @Test("Shows safe command arguments without changing them")
    func formatsHomebrewUpdateCommand() {
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
            arguments: [
                "upgrade",
                "--formula",
                "--",
                "custom/tools/libxml++@2.0"
            ]
        )

        #expect(CommandTextFormatter().string(for: request) ==
            "/opt/homebrew/bin/brew upgrade --formula -- custom/tools/libxml++@2.0")
    }

    @Test("Quotes spaces, empty arguments, and single quotes unambiguously")
    func quotesShellSensitiveValues() {
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/Applications/Homebrew Test/bin/brew"),
            arguments: ["", "owner/tap/o'clock"]
        )

        #expect(CommandTextFormatter().string(for: request) ==
            "'/Applications/Homebrew Test/bin/brew' '' 'owner/tap/o'\\''clock'")
    }
}
