nonisolated struct HomebrewPackageMetadata: Equatable, Identifiable, Sendable {
    let name: String
    let inventoryName: String
    let kind: HomebrewPackage.Kind
    let upgradeEligibility: HomebrewPackageUpgradeEligibility

    var id: HomebrewPackage.ID { HomebrewPackage.ID(kind: kind, name: name) }

    init(
        name: String,
        inventoryName: String? = nil,
        kind: HomebrewPackage.Kind,
        upgradeEligibility: HomebrewPackageUpgradeEligibility
    ) {
        self.name = name
        self.inventoryName = inventoryName ?? name
        self.kind = kind
        self.upgradeEligibility = upgradeEligibility
    }
}
