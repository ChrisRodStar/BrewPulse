nonisolated struct HomebrewPackageOperationOutput: Equatable, Identifiable, Sendable {
    enum Status: Equatable, Sendable {
        case succeeded
        case failed(message: String)
        case cancelled
    }

    let plan: HomebrewOperationPlan
    let status: Status
    let result: CommandResult?

    var id: HomebrewPackage.ID { plan.id }

    var guidance: [HomebrewCommandGuidance] {
        result.map(HomebrewCommandGuidance.detect) ?? []
    }

    var textForCopying: String {
        guard let result else { return "" }

        return switch (result.standardOutput.isEmpty, result.standardError.isEmpty) {
        case (false, true):
            result.standardOutput
        case (true, false):
            result.standardError
        case (false, false):
            Self.labeledTranscript(
                standardOutput: result.standardOutput,
                standardError: result.standardError
            )
        case (true, true):
            ""
        }
    }

    private static func labeledTranscript(
        standardOutput: String,
        standardError: String
    ) -> String {
        let separator = standardOutput.hasSuffix("\n") ? "\n" : "\n\n"
        return "Standard Output:\n"
            + standardOutput
            + separator
            + "Standard Error:\n"
            + standardError
    }
}
