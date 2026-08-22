import Darwin
import Foundation

final class ProcessCommandRunner: CommandRunning, @unchecked Sendable {
    private struct ActiveCommand {
        let processIdentifier: pid_t
        var stopReason: CommandTerminationReason?
        var stopRequestedAt: ContinuousClock.Instant?
        var sentTerminate = false
        var sentKill = false
    }

    private let stateLock = NSLock()
    private let stopGracePeriod: Duration
    nonisolated(unsafe) private var activeCommand: ActiveCommand?
    nonisolated(unsafe) private var cancellationRequested = false

    nonisolated init(stopGracePeriod: Duration = .seconds(5)) {
        self.stopGracePeriod = stopGracePeriod
    }

    nonisolated func run(
        _ request: CommandRequest,
        policy: CommandExecutionPolicy
    ) throws -> CommandResult {
        let fileManager = FileManager.default
        let outputDirectoryURL = fileManager.temporaryDirectory
            .appendingPathComponent(
                "BrewPulse-Command-\(UUID().uuidString)",
                isDirectory: true
            )

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

        let startedAt = Date()
        let clock = ContinuousClock()
        let start = clock.now
        let processIdentifier: pid_t
        do {
            processIdentifier = try spawn(
                request,
                standardOutputDescriptor: standardOutputHandle.fileDescriptor,
                standardErrorDescriptor: standardErrorHandle.fileDescriptor
            )
        } catch {
            stateLock.withLock {
                cancellationRequested = false
            }
            throw error
        }

        let shouldCancel = stateLock.withLock {
            let stopReason: CommandTerminationReason? = cancellationRequested
                ? .cancelled
                : nil
            activeCommand = ActiveCommand(
                processIdentifier: processIdentifier,
                stopReason: stopReason,
                stopRequestedAt: stopReason == nil ? nil : ContinuousClock().now
            )
            return stopReason != nil
        }
        defer {
            stateLock.withLock {
                if activeCommand?.processIdentifier == processIdentifier {
                    activeCommand = nil
                    cancellationRequested = false
                }
            }
        }

        if shouldCancel {
            signalProcessGroup(processIdentifier, signal: SIGINT)
        }

        let terminationStatus = try waitForExit(
            for: processIdentifier,
            timeout: policy.timeout
        )
        let duration = start.duration(to: clock.now)

        let terminationReason = stateLock.withLock {
            activeCommand?.stopReason ?? .exited
        }
        if terminationReason != .exited {
            terminateRemainingProcessGroup(processIdentifier)
        }

        try standardOutputHandle.close()
        try standardErrorHandle.close()
        let outputData = try Data(contentsOf: standardOutputURL)
        let errorData = try Data(contentsOf: standardErrorURL)

        return CommandResult(
            request: request,
            standardOutput: String(decoding: outputData, as: UTF8.self),
            standardError: String(decoding: errorData, as: UTF8.self),
            terminationStatus: terminationStatus,
            startedAt: startedAt,
            duration: duration,
            terminationReason: terminationReason
        )
    }

    nonisolated func cancelCurrentCommand() {
        let processIdentifier = stateLock.withLock { () -> pid_t? in
            cancellationRequested = true
            guard var activeCommand,
                  activeCommand.stopReason == nil else {
                return nil
            }
            activeCommand.stopReason = .cancelled
            activeCommand.stopRequestedAt = ContinuousClock().now
            self.activeCommand = activeCommand
            return activeCommand.processIdentifier
        }

        guard let processIdentifier else { return }
        signalProcessGroup(processIdentifier, signal: SIGINT)
    }

    nonisolated private func spawn(
        _ request: CommandRequest,
        standardOutputDescriptor: Int32,
        standardErrorDescriptor: Int32
    ) throws -> pid_t {
        var fileActions: posix_spawn_file_actions_t?
        try checkPOSIX(posix_spawn_file_actions_init(&fileActions))
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        try checkPOSIX(
            posix_spawn_file_actions_adddup2(
                &fileActions,
                standardOutputDescriptor,
                STDOUT_FILENO
            )
        )
        try checkPOSIX(
            posix_spawn_file_actions_adddup2(
                &fileActions,
                standardErrorDescriptor,
                STDERR_FILENO
            )
        )

        var attributes: posix_spawnattr_t?
        try checkPOSIX(posix_spawnattr_init(&attributes))
        defer { posix_spawnattr_destroy(&attributes) }

        var defaultSignals = sigset_t()
        sigemptyset(&defaultSignals)
        sigaddset(&defaultSignals, SIGINT)
        sigaddset(&defaultSignals, SIGTERM)
        sigaddset(&defaultSignals, SIGQUIT)
        try checkPOSIX(
            posix_spawnattr_setsigdefault(&attributes, &defaultSignals)
        )

        let flags = Int16(
            POSIX_SPAWN_SETSID
                | POSIX_SPAWN_CLOEXEC_DEFAULT
                | POSIX_SPAWN_SETSIGDEF
        )
        try checkPOSIX(posix_spawnattr_setflags(&attributes, flags))

        let arguments = [request.executableURL.path] + request.arguments
        var mutableArguments: [UnsafeMutablePointer<CChar>] = []
        do {
            for argument in arguments {
                guard let duplicate = strdup(argument) else {
                    throw posixError(ENOMEM)
                }
                mutableArguments.append(duplicate)
            }
        } catch {
            mutableArguments.forEach { free($0) }
            throw error
        }
        defer { mutableArguments.forEach { free($0) } }

        var argumentVector = mutableArguments.map(Optional.some) + [nil]
        var processIdentifier: pid_t = 0
        let spawnResult = request.executableURL.path.withCString { executablePath in
            argumentVector.withUnsafeMutableBufferPointer { arguments in
                posix_spawn(
                    &processIdentifier,
                    executablePath,
                    &fileActions,
                    &attributes,
                    arguments.baseAddress,
                    environ
                )
            }
        }
        try checkPOSIX(spawnResult)
        return processIdentifier
    }

    nonisolated private func waitForExit(
        for processIdentifier: pid_t,
        timeout: Duration?
    ) throws -> Int32 {
        var status: Int32 = 0
        let clock = ContinuousClock()
        let timeoutDeadline = timeout.map { clock.now.advanced(by: $0) }

        while true {
            let waitResult = waitpid(processIdentifier, &status, WNOHANG)
            if waitResult == processIdentifier {
                break
            }
            if waitResult == -1, errno != EINTR {
                throw posixError(errno)
            }

            if let timeoutDeadline, clock.now >= timeoutDeadline {
                requestTimeout(for: processIdentifier)
            }
            enforceStopEscalation(for: processIdentifier, now: clock.now)
            Thread.sleep(forTimeInterval: 0.01)
        }

        let terminatingSignal = status & 0x7f
        if terminatingSignal == 0 {
            return (status >> 8) & 0xff
        }
        return 128 + terminatingSignal
    }

    nonisolated private func requestTimeout(for processIdentifier: pid_t) {
        let shouldStop = stateLock.withLock {
            guard var activeCommand,
                  activeCommand.processIdentifier == processIdentifier,
                  activeCommand.stopReason == nil else {
                return false
            }
            activeCommand.stopReason = .timedOut
            activeCommand.stopRequestedAt = ContinuousClock().now
            self.activeCommand = activeCommand
            return true
        }

        guard shouldStop else { return }
        signalProcessGroup(processIdentifier, signal: SIGINT)
    }

    nonisolated private func enforceStopEscalation(
        for processIdentifier: pid_t,
        now: ContinuousClock.Instant
    ) {
        let signal = stateLock.withLock { () -> Int32? in
            guard var activeCommand,
                  activeCommand.processIdentifier == processIdentifier,
                  let stopRequestedAt = activeCommand.stopRequestedAt else {
                return nil
            }

            let elapsed = stopRequestedAt.duration(to: now)
            if elapsed >= stopGracePeriod + stopGracePeriod,
               !activeCommand.sentKill {
                activeCommand.sentKill = true
                self.activeCommand = activeCommand
                return SIGKILL
            }
            if elapsed >= stopGracePeriod,
               !activeCommand.sentTerminate {
                activeCommand.sentTerminate = true
                self.activeCommand = activeCommand
                return SIGTERM
            }
            return nil
        }

        guard let signal else { return }
        signalProcessGroup(processIdentifier, signal: signal)
    }

    nonisolated private func terminateRemainingProcessGroup(
        _ processIdentifier: pid_t
    ) {
        guard processGroupExists(processIdentifier) else { return }

        signalProcessGroup(processIdentifier, signal: SIGTERM)
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: stopGracePeriod)
        while clock.now < deadline, processGroupExists(processIdentifier) {
            Thread.sleep(forTimeInterval: 0.01)
        }

        if processGroupExists(processIdentifier) {
            signalProcessGroup(processIdentifier, signal: SIGKILL)
        }
    }

    nonisolated private func signalProcessGroup(
        _ processIdentifier: pid_t,
        signal: Int32
    ) {
        _ = Darwin.kill(-processIdentifier, signal)
    }

    nonisolated private func processGroupExists(
        _ processIdentifier: pid_t
    ) -> Bool {
        if Darwin.kill(-processIdentifier, 0) == 0 {
            return true
        }
        return errno == EPERM
    }

    nonisolated private func checkPOSIX(_ result: Int32) throws {
        guard result == 0 else { throw posixError(result) }
    }

    nonisolated private func posixError(_ code: Int32) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }
}

private extension Duration {
    nonisolated var timeInterval: TimeInterval {
        let components = self.components
        return max(
            0,
            TimeInterval(components.seconds)
                + TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
        )
    }
}
