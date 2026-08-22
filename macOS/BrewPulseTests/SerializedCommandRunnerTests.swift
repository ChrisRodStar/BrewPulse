import Foundation
import Testing
@testable import BrewPulse

@Suite("Serialized command runner")
struct SerializedCommandRunnerTests {
    @Test("Does not overlap concurrent commands")
    func serializesConcurrentCommands() {
        let trackingRunner = ConcurrencyTrackingCommandRunner()
        let runner = SerializedCommandRunner(base: trackingRunner)
        let request = CommandRequest(
            executableURL: URL(fileURLWithPath: "/test/command"),
            arguments: []
        )
        let ready = DispatchSemaphore(value: 0)
        let start = DispatchSemaphore(value: 0)
        let commands = DispatchGroup()
        let queue = DispatchQueue(
            label: "BrewPulseTests.SerializedCommandRunner",
            attributes: .concurrent
        )

        for _ in 0..<2 {
            commands.enter()
            queue.async {
                ready.signal()
                start.wait()
                defer { commands.leave() }

                do {
                    _ = try runner.run(request)
                } catch {
                    Issue.record("Unexpected command error: \(error)")
                }
            }
        }

        ready.wait()
        ready.wait()
        start.signal()
        start.signal()
        commands.wait()

        #expect(trackingRunner.maximumConcurrentExecutions == 1)
    }
}

private final class ConcurrencyTrackingCommandRunner: CommandRunning, @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var activeExecutions = 0
    nonisolated(unsafe) private var recordedMaximumConcurrentExecutions = 0

    nonisolated var maximumConcurrentExecutions: Int {
        lock.withLock { recordedMaximumConcurrentExecutions }
    }

    nonisolated func run(
        _ request: CommandRequest,
        policy: CommandExecutionPolicy
    ) throws -> CommandResult {
        lock.withLock {
            activeExecutions += 1
            recordedMaximumConcurrentExecutions = max(
                recordedMaximumConcurrentExecutions,
                activeExecutions
            )
        }

        Thread.sleep(forTimeInterval: 0.1)

        lock.withLock {
            activeExecutions -= 1
        }

        return CommandResult(
            request: request,
            standardOutput: "",
            standardError: "",
            terminationStatus: 0,
            startedAt: .distantPast,
            duration: .zero
        )
    }
}
