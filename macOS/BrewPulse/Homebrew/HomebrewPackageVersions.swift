nonisolated struct HomebrewPackageVersions: Equatable, Sendable {
    let installed: [String]
    let available: String?

    init(installed: [String], available: String? = nil) {
        self.installed = installed
        self.available = available
    }
}
