nonisolated struct HomebrewOutdatedReport: Equatable, Sendable {
    let outdatedData: HomebrewOutdatedData
    let packageMetadata: [HomebrewPackageMetadata]
    let commandResults: [CommandResult]
}
