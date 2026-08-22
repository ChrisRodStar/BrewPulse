import Foundation
@testable import BrewPulse

final class SuspendedCommandRunner: CommandRunning, @unchecked Sendable {
    typealias Handler = @Sendable (CommandRequest) throws -> CommandResult

    private let handler: Handler
    private let gate = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    nonisolated(unsafe) private var shouldSuspend = true
    nonisolated(unsafe) private var recordedCancellationRequested = false
    nonisolated(unsafe) private var recordedRequests: [CommandRequest] = []

    nonisolated init(handler: @escaping Handler) {
        self.handler = handler
    }

    nonisolated func run(
        _ request: CommandRequest,
        policy: CommandExecutionPolicy
    ) throws -> CommandResult {
        lock.lock()
        recordedRequests.append(request)
        let suspendsThisRequest = shouldSuspend
        shouldSuspend = false
        lock.unlock()

        if suspendsThisRequest {
            gate.wait()
        }

        return try handler(request)
    }

    nonisolated func resume() {
        gate.signal()
    }

    nonisolated var cancellationRequested: Bool {
        lock.withLock { recordedCancellationRequested }
    }

    nonisolated var requests: [CommandRequest] {
        lock.withLock { recordedRequests }
    }

    nonisolated func cancelCurrentCommand() {
        lock.withLock {
            recordedCancellationRequested = true
        }
    }
}
