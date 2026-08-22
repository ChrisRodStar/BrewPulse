import Foundation

final class SerializedCommandRunner: CommandRunning {
    private let base: any CommandRunning
    private let lock = NSLock()

    nonisolated init(base: any CommandRunning) {
        self.base = base
    }

    nonisolated func run(
        _ request: CommandRequest,
        policy: CommandExecutionPolicy
    ) throws -> CommandResult {
        lock.lock()
        defer { lock.unlock() }

        return try base.run(request, policy: policy)
    }

    nonisolated func cancelCurrentCommand() {
        base.cancelCurrentCommand()
    }
}
