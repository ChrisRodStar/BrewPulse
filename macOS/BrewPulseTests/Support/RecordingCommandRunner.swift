import Foundation
@testable import BrewPulse

enum RecordingCommandRunnerError: Error {
    case unexpectedRequest(CommandRequest)
}

final class RecordingCommandRunner: CommandRunning, @unchecked Sendable {
    typealias Handler = @Sendable (CommandRequest) throws -> CommandResult

    private let handler: Handler
    private let lock = NSLock()
    nonisolated(unsafe) private var recordedRequests: [CommandRequest] = []
    nonisolated(unsafe) private var recordedCancellationRequested = false

    nonisolated init(handler: @escaping Handler) {
        self.handler = handler
    }

    nonisolated var requests: [CommandRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recordedRequests
    }

    nonisolated var cancellationRequested: Bool {
        lock.withLock { recordedCancellationRequested }
    }

    nonisolated func run(_ request: CommandRequest) throws -> CommandResult {
        lock.lock()
        recordedRequests.append(request)
        lock.unlock()

        return try handler(request)
    }

    nonisolated func cancelCurrentCommand() {
        lock.withLock {
            recordedCancellationRequested = true
        }
    }
}

extension CommandResult {
    nonisolated static func testResult(
        for request: CommandRequest,
        standardOutput: String = "",
        standardError: String = "",
        terminationStatus: Int32 = 0
    ) -> CommandResult {
        CommandResult(
            request: request,
            standardOutput: standardOutput,
            standardError: standardError,
            terminationStatus: terminationStatus,
            startedAt: .distantPast,
            duration: .zero
        )
    }
}
