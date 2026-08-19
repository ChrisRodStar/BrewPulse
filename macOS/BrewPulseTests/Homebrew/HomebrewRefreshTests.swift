import Foundation
import Testing
@testable import BrewPulse

@Suite("Homebrew refresh workflow")
struct HomebrewRefreshTests {
    private let brewURL = URL(fileURLWithPath: "/test/homebrew/bin/brew")

    @Test("Preserves inventory output when update metadata fails")
    func preservesEarlierOutputOnFailure() {
        let runner = RecordingCommandRunner { request in
            switch request.arguments {
            case ["list", "--cask", "--versions"]:
                return .testResult(for: request, standardOutput: "example-app 1.0\n")
            case ["list", "--formula", "--versions"]:
                return .testResult(for: request, standardOutput: "example-tool 2.0\n")
            case ["--version"]:
                return .testResult(for: request, standardOutput: "Homebrew 5.0.0\n")
            case ["outdated", "--json=v2"]:
                return .testResult(
                    for: request,
                    standardOutput: #"{"formulae":[],"casks":[]}"#
                )
            case ["info", "--json=v2", "--installed"]:
                return .testResult(
                    for: request,
                    standardOutput: "partial metadata\n",
                    standardError: "metadata failed\n",
                    terminationStatus: 4
                )
            default:
                throw RecordingCommandRunnerError.unexpectedRequest(request)
            }
        }
        let service = HomebrewService(
            commandRunner: runner,
            executableURL: brewURL
        )

        do {
            _ = try service.inventoryWithUpdateAvailability()
            Issue.record("Expected the refresh to fail")
        } catch HomebrewError.commandFailed(let results) {
            #expect(results.map(\.standardOutput) == [
                "example-app 1.0\n",
                "example-tool 2.0\n",
                "Homebrew 5.0.0\n",
                #"{"formulae":[],"casks":[]}"#,
                "partial metadata\n"
            ])
            #expect(results.last?.standardError == "metadata failed\n")
            #expect(results.last?.terminationStatus == 4)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
