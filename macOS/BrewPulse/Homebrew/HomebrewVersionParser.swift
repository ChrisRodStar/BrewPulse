import Foundation

nonisolated struct HomebrewVersionParser: Sendable {
    func parse(_ output: String) -> String? {
        guard let firstLine = output.split(whereSeparator: { $0.isNewline }).first else {
            return nil
        }

        let line = String(firstLine)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return nil }

        let prefix = "Homebrew "
        return line.hasPrefix(prefix)
            ? String(line.dropFirst(prefix.count))
            : line
    }
}
