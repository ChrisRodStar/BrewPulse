nonisolated enum HomebrewCommandGuidance: Hashable, Sendable {
    case administratorAccess
    case externalInteraction

    static func detect(in result: CommandResult) -> [Self] {
        let output = (result.standardOutput + "\n" + result.standardError)
            .lowercased()
        var guidance: [Self] = []

        if administratorMarkers.contains(where: output.contains) {
            guidance.append(.administratorAccess)
        }
        if interactionMarkers.contains(where: output.contains) {
            guidance.append(.externalInteraction)
        }

        return guidance
    }

    private static let administratorMarkers = [
        "administrator privileges",
        "password:",
        "permission denied",
        "requires root",
        "sudo ",
        "your password may be necessary"
    ]

    private static let interactionMarkers = [
        "complete the installation",
        "follow the instructions",
        "manual intervention",
        "open the installer",
        "requires user interaction"
    ]
}
