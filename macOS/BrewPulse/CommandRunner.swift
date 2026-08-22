import Foundation

nonisolated struct CommandRequest: Equatable, Sendable {
    let executableURL: URL
    let arguments: [String]
}

nonisolated struct CommandExecutionPolicy: Equatable, Sendable {
    let timeout: Duration?

    static let unbounded = CommandExecutionPolicy(timeout: nil)

    static func timeout(after duration: Duration) -> CommandExecutionPolicy {
        CommandExecutionPolicy(timeout: duration)
    }
}

nonisolated enum CommandTerminationReason: Equatable, Sendable {
    case exited
    case cancelled
    case timedOut
}

nonisolated struct CommandResult: Equatable, Sendable {
    let request: CommandRequest
    let standardOutput: String
    let standardError: String
    let terminationStatus: Int32
    let startedAt: Date
    let duration: Duration
    let terminationReason: CommandTerminationReason

    init(
        request: CommandRequest,
        standardOutput: String,
        standardError: String,
        terminationStatus: Int32,
        startedAt: Date,
        duration: Duration,
        terminationReason: CommandTerminationReason = .exited
    ) {
        self.request = request
        self.standardOutput = standardOutput
        self.standardError = standardError
        self.terminationStatus = terminationStatus
        self.startedAt = startedAt
        self.duration = duration
        self.terminationReason = terminationReason
    }
}

protocol CommandRunning: Sendable {
    nonisolated func run(
        _ request: CommandRequest,
        policy: CommandExecutionPolicy
    ) throws -> CommandResult
    nonisolated func cancelCurrentCommand()
}

extension CommandRunning {
    nonisolated func run(_ request: CommandRequest) throws -> CommandResult {
        try run(request, policy: .unbounded)
    }

    nonisolated func cancelCurrentCommand() {}
}
