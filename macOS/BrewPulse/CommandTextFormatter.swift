import Foundation

nonisolated struct CommandTextFormatter: Sendable {
    func string(for request: CommandRequest) -> String {
        ([request.executableURL.path] + request.arguments)
            .map(Self.quote)
            .joined(separator: " ")
    }

    private static func quote(_ argument: String) -> String {
        guard !argument.isEmpty else { return "''" }
        guard argument.unicodeScalars.allSatisfy(isUnquotedSafe) else {
            return "'" + argument.replacingOccurrences(
                of: "'",
                with: "'\\''"
            ) + "'"
        }

        return argument
    }

    private static func isUnquotedSafe(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 48...57, 65...90, 97...122:
            true
        default:
            "-._/@%+=:,".unicodeScalars.contains(scalar)
        }
    }
}
