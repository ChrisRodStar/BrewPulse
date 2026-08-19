nonisolated struct HomebrewInventoryMerger: Sendable {
    func merge(
        inventory: HomebrewInventory,
        outdatedPackages: [HomebrewOutdatedPackage],
        packageMetadata: [HomebrewPackageMetadata]
    ) -> HomebrewInventory {
        var outdatedByID: [HomebrewPackage.ID: HomebrewOutdatedPackage] = [:]
        for package in outdatedPackages {
            outdatedByID[package.id] = package
        }

        var metadataByID: [HomebrewPackage.ID: HomebrewPackageMetadata] = [:]
        var metadataByInventoryID: [HomebrewPackage.ID: HomebrewPackageMetadata] = [:]
        for metadata in packageMetadata {
            metadataByID[metadata.id] = metadata
            metadataByInventoryID[
                HomebrewPackage.ID(
                    kind: metadata.kind,
                    name: metadata.inventoryName
                )
            ] = metadata
        }

        return HomebrewInventory(
            applications: merge(
                inventory.applications,
                outdatedByID: outdatedByID,
                metadataByID: metadataByID,
                metadataByInventoryID: metadataByInventoryID
            ),
            formulae: merge(
                inventory.formulae,
                outdatedByID: outdatedByID,
                metadataByID: metadataByID,
                metadataByInventoryID: metadataByInventoryID
            )
        )
    }

    private func merge(
        _ packages: [HomebrewPackage],
        outdatedByID: [HomebrewPackage.ID: HomebrewOutdatedPackage],
        metadataByID: [HomebrewPackage.ID: HomebrewPackageMetadata],
        metadataByInventoryID: [HomebrewPackage.ID: HomebrewPackageMetadata]
    ) -> [HomebrewPackage] {
        packages.map { package in
            let metadata = metadataByID[package.id]
                ?? metadataByInventoryID[package.id]
            let outdatedPackage = outdatedByID[metadata?.id ?? package.id]
                ?? outdatedByID[package.id]
            let metadataEligibility = metadata?.upgradeEligibility
                ?? HomebrewPackageUpgradeEligibility(
                    blockers: [.metadataUnavailable]
                )
            let upgradeEligibility = outdatedPackage.map {
                metadataEligibility.merging($0.upgradeEligibility)
            } ?? metadataEligibility

            return HomebrewPackage(
                name: metadata?.name ?? package.name,
                versions: HomebrewPackageVersions(
                    installed: package.versions.installed,
                    available: outdatedPackage?.versions.available
                ),
                kind: package.kind,
                upgradeEligibility: upgradeEligibility
            )
        }
    }
}
