import Foundation
import Darwin
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
        let runner = ProcessCommandRunner(
            stopGracePeriod: .milliseconds(50)
        )
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                "printf started; while :; do :; done"
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
        #expect(result.standardOutput == "started")
        #expect(result.terminationReason == .cancelled)
    }

    @Test("Times out a stalled command and preserves its partial output")
    func timesOutStalledCommand() throws {
        let runner = ProcessCommandRunner(
            stopGracePeriod: .milliseconds(50)
        )
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "printf started; while :; do :; done"]
        )

        let result = try runner.run(
            request,
            policy: .timeout(after: .milliseconds(100))
        )

        #expect(result.terminationStatus != 0)
        #expect(result.standardOutput == "started")
        #expect(result.terminationReason == .timedOut)
        #expect(result.duration < .seconds(2))
    }

    @Test("Stops child processes in the command's process group")
    func cancelsChildProcesses() async throws {
        let runner = ProcessCommandRunner(
            stopGracePeriod: .milliseconds(50)
        )
        let childPIDURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrewPulse-child-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: childPIDURL) }
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                """
                /bin/sh -c 'while :; do /bin/sleep 1; done' &
                child=$!
                printf '%s' "$child" > "$1"
                while :; do :; done
                """,
                "brewpulse-test",
                childPIDURL.path
            ]
        )
        let command = Task.detached {
            try runner.run(request)
        }

        for _ in 0..<200 where !FileManager.default.fileExists(
            atPath: childPIDURL.path
        ) {
            try await Task.sleep(for: .milliseconds(10))
        }
        let childPIDText = try String(contentsOf: childPIDURL, encoding: .utf8)
        let childPID = try #require(pid_t(childPIDText))

        runner.cancelCurrentCommand()
        let result = try await command.value

        #expect(result.terminationReason == .cancelled)
        #expect(Darwin.kill(childPID, 0) == -1)
        #expect(errno == ESRCH)
    }
}
