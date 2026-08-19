import Foundation

final class ProcessCommandRunner: CommandRunning, @unchecked Sendable {
    private let stateLock = NSLock()
    nonisolated(unsafe) private var activeProcess: Process?
    nonisolated(unsafe) private var cancellationRequested = false
    nonisolated(unsafe) private var interruptSent = false

    nonisolated func run(_ request: CommandRequest) throws -> CommandResult {
        let fileManager = FileManager.default
        let outputDirectoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("BrewPulse-Command-\(UUID().uuidString)", isDirectory: true)

        try fileManager.createDirectory(
            at: outputDirectoryURL,
            withIntermediateDirectories: false
        )
        defer { try? fileManager.removeItem(at: outputDirectoryURL) }

        let standardOutputURL = outputDirectoryURL.appendingPathComponent("stdout")
        let standardErrorURL = outputDirectoryURL.appendingPathComponent("stderr")
        try Data().write(to: standardOutputURL)
        try Data().write(to: standardErrorURL)

        let standardOutputHandle = try FileHandle(forWritingTo: standardOutputURL)
        let standardErrorHandle = try FileHandle(forWritingTo: standardErrorURL)
        defer {
            try? standardOutputHandle.close()
            try? standardErrorHandle.close()
        }

        let process = Process()
        process.executableURL = request.executableURL
        process.arguments = request.arguments
        process.standardOutput = standardOutputHandle
        process.standardError = standardErrorHandle

        stateLock.withLock {
            activeProcess = process
        }
        defer {
            stateLock.withLock {
                if activeProcess === process {
                    activeProcess = nil
                    cancellationRequested = false
                    interruptSent = false
                }
            }
        }

        let startedAt = Date()
        let clock = ContinuousClock()
        let start = clock.now

        try process.run()
        let shouldInterrupt = stateLock.withLock {
            guard cancellationRequested,
                  !interruptSent,
                  activeProcess === process else {
                return false
            }
            interruptSent = true
            return true
        }
        if shouldInterrupt {
            interrupt(process)
        }
        process.waitUntilExit()
        let duration = start.duration(to: clock.now)

        try standardOutputHandle.close()
        try standardErrorHandle.close()
        let outputData = try Data(contentsOf: standardOutputURL)
        let errorData = try Data(contentsOf: standardErrorURL)

        return CommandResult(
            request: request,
            standardOutput: String(decoding: outputData, as: UTF8.self),
            standardError: String(decoding: errorData, as: UTF8.self),
            terminationStatus: process.terminationStatus,
            startedAt: startedAt,
            duration: duration
        )
    }

    nonisolated func cancelCurrentCommand() {
        let process = stateLock.withLock { () -> Process? in
            cancellationRequested = true
            guard let activeProcess,
                  activeProcess.isRunning,
                  !interruptSent else {
                return nil
            }
            interruptSent = true
            return activeProcess
        }

        guard let process else { return }
        interrupt(process)
    }

    nonisolated private func interrupt(_ process: Process) {
        let processIdentifier = process.processIdentifier
        process.interrupt()

        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + 5
        ) { [weak self] in
            self?.terminateIfStillRunning(processIdentifier)
        }
    }

    nonisolated private func terminateIfStillRunning(
        _ processIdentifier: Int32
    ) {
        let process = stateLock.withLock { () -> Process? in
            guard let activeProcess,
                  activeProcess.isRunning,
                  activeProcess.processIdentifier == processIdentifier else {
                return nil
            }
            return activeProcess
        }
        process?.terminate()
    }
}
