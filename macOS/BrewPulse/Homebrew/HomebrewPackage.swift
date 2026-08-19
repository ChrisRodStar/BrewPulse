import Foundation

nonisolated struct HomebrewPackage: Equatable, Identifiable, Sendable {
    nonisolated struct ID: Hashable, Sendable {
        let kind: Kind
        let name: String
    }

    nonisolated enum Kind: String, Hashable, Sendable {
        case formula = "Formulae"
        case cask = "Applications"
    }

    let name: String
    let versions: HomebrewPackageVersions
    let kind: Kind
    let upgradeEligibility: HomebrewPackageUpgradeEligibility

    init(
        name: String,
        versions: HomebrewPackageVersions,
        kind: Kind,
        upgradeEligibility: HomebrewPackageUpgradeEligibility = HomebrewPackageUpgradeEligibility(
            blockers: [.metadataUnavailable]
        )
    ) {
        self.name = name
        self.versions = versions
        self.kind = kind
        self.upgradeEligibility = upgradeEligibility
    }

    var id: ID { ID(kind: kind, name: name) }

    var isStandardUpgradeAvailable: Bool {
        versions.available != nil && upgradeEligibility.allowsStandardUpgrade
    }
}
