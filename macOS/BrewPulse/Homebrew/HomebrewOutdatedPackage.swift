nonisolated struct HomebrewOutdatedPackage: Equatable, Identifiable, Sendable {
    let name: String
    let versions: HomebrewPackageVersions
    let kind: HomebrewPackage.Kind
    let upgradeEligibility: HomebrewPackageUpgradeEligibility

    var id: HomebrewPackage.ID { HomebrewPackage.ID(kind: kind, name: name) }
}
