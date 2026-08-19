import Foundation

nonisolated struct CommandRequest: Equatable, Sendable {
    let executableURL: URL
    let arguments: [String]
}

nonisolated struct CommandResult: Equatable, Sendable {
    let request: CommandRequest
    let standardOutput: String
    let standardError: String
    let terminationStatus: Int32
    let startedAt: Date
    let duration: Duration
}

protocol CommandRunning: Sendable {
    nonisolated func run(_ request: CommandRequest) throws -> CommandResult
    nonisolated func cancelCurrentCommand()
}

extension CommandRunning {
    nonisolated func cancelCurrentCommand() {}
}
