import Foundation
import Testing
@testable import BrewPulse

@Suite("Process command runner")
struct ProcessCommandRunnerTests {
    @Test("Captures output, exit status, and timing metadata")
    func capturesCommandResult() throws {
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "printf standard-output; printf standard-error >&2; exit 7"]
        )

        let result = try ProcessCommandRunner().run(request)

        #expect(result.request == request)
        #expect(result.standardOutput == "standard-output")
        #expect(result.standardError == "standard-error")
        #expect(result.terminationStatus == 7)
        #expect(result.startedAt <= Date())
        #expect(result.duration >= .zero)
    }

    @Test("Captures large standard output and error without deadlocking")
    func capturesLargeOutput() throws {
        let byteCount = 1_048_576
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                """
                /usr/bin/yes output | /usr/bin/head -c \(byteCount)
                /usr/bin/yes error | /usr/bin/head -c \(byteCount) >&2
                """
            ]
        )

        let result = try ProcessCommandRunner().run(request)

        #expect(result.terminationStatus == 0)
        #expect(result.standardOutput.utf8.count == byteCount)
        #expect(result.standardError.utf8.count == byteCount)
        #expect(result.standardOutput.hasPrefix("output\n"))
        #expect(result.standardError.hasPrefix("error\n"))
    }

    @Test("Interrupts an active command and returns its partial output")
    func cancelsActiveCommand() async throws {
        let runner = ProcessCommandRunner()
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                "trap 'printf interrupted; exit 130' INT; while :; do :; done"
            ]
        )
        let command = Task.detached {
            try runner.run(request)
        }

        try await Task.sleep(for: .milliseconds(100))
        runner.cancelCurrentCommand()
        let result = try await command.value

        #expect(result.request == request)
        #expect(result.terminationStatus != 0)
        #expect(result.standardOutput == "interrupted")
    }
}
