nonisolated struct HomebrewOutdatedData: Decodable, Equatable, Sendable {
    let packages: [HomebrewOutdatedPackage]

    private nonisolated struct RawPackage: Decodable {
        let name: String
        let installedVersions: [String]
        let currentVersion: String
        let pinned: Bool
        let pinnedVersion: String?

        private nonisolated enum CodingKeys: String, CodingKey {
            case name
            case installedVersions = "installed_versions"
            case currentVersion = "current_version"
            case pinned
            case pinnedVersion = "pinned_version"
        }

        func package(kind: HomebrewPackage.Kind) -> HomebrewOutdatedPackage {
            HomebrewOutdatedPackage(
                name: name,
                versions: HomebrewPackageVersions(
                    installed: installedVersions,
                    available: currentVersion
                ),
                kind: kind,
                upgradeEligibility: HomebrewPackageUpgradeEligibility(
                    blockers: pinned ? [.pinned(version: pinnedVersion)] : []
                )
            )
        }
    }

    private nonisolated enum CodingKeys: String, CodingKey {
        case formulae
        case casks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let formulae = try container.decode([RawPackage].self, forKey: .formulae)
        let casks = try container.decode([RawPackage].self, forKey: .casks)

        packages = formulae.map { $0.package(kind: .formula) }
            + casks.map { $0.package(kind: .cask) }
    }
}
