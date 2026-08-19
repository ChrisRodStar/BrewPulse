import Foundation
import Testing
@testable import BrewPulse

@Suite("Homebrew command guidance")
struct HomebrewCommandGuidanceTests {
    @Test("Detects administrator access messages")
    func detectsAdministratorAccess() {
        let result = makeResult(
            standardError: "Your password may be necessary to finish this update.\n"
        )

        #expect(HomebrewCommandGuidance.detect(in: result) == [
            .administratorAccess
        ])
    }

    @Test("Detects external interaction messages")
    func detectsExternalInteraction() {
        let result = makeResult(
            standardOutput: "Follow the instructions in the installer window.\n"
        )

        #expect(HomebrewCommandGuidance.detect(in: result) == [
            .externalInteraction
        ])
    }

    @Test("Reports each relevant kind of guidance once")
    func deduplicatesGuidance() {
        let result = makeResult(
            standardOutput: "Password:\nPassword:\n",
            standardError: "Requires user interaction. Follow the instructions.\n"
        )

        #expect(HomebrewCommandGuidance.detect(in: result) == [
            .administratorAccess,
            .externalInteraction
        ])
    }

    @Test("Does not infer requirements from ordinary output")
    func ignoresOrdinaryOutput() {
        let result = makeResult(
            standardOutput: "Pouring git--2.50.1.arm64_sonoma.bottle.tar.gz\n"
        )

        #expect(HomebrewCommandGuidance.detect(in: result).isEmpty)
    }

    private func makeResult(
        standardOutput: String = "",
        standardError: String = ""
    ) -> CommandResult {
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/test/homebrew/bin/brew"),
            arguments: ["upgrade", "--formula", "--", "git"]
        )
        return .testResult(
            for: request,
            standardOutput: standardOutput,
            standardError: standardError
        )
    }
}
