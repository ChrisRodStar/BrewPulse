nonisolated struct HomebrewPackageMetadataData: Decodable, Equatable, Sendable {
    let packages: [HomebrewPackageMetadata]

    private nonisolated struct Formula: Decodable {
        let name: String
        let fullName: String
        let pinned: Bool
        let disabled: Bool

        private nonisolated enum CodingKeys: String, CodingKey {
            case name
            case fullName = "full_name"
            case pinned
            case disabled
        }

        var metadata: HomebrewPackageMetadata {
            var blockers: Set<HomebrewPackageUpgradeEligibility.Blocker> = []
            if pinned {
                blockers.insert(.pinned(version: nil))
            }
            if disabled {
                blockers.insert(.disabled)
            }

            return HomebrewPackageMetadata(
                name: fullName,
                inventoryName: name,
                kind: .formula,
                upgradeEligibility: HomebrewPackageUpgradeEligibility(blockers: blockers)
            )
        }
    }

    private nonisolated struct Cask: Decodable {
        let token: String
        let version: String?
        let autoUpdates: Bool?
        let pinned: Bool
        let pinnedVersion: String?
        let disabled: Bool

        private nonisolated enum CodingKeys: String, CodingKey {
            case token
            case version
            case autoUpdates = "auto_updates"
            case pinned
            case pinnedVersion = "pinned_version"
            case disabled
        }

        var metadata: HomebrewPackageMetadata {
            var blockers: Set<HomebrewPackageUpgradeEligibility.Blocker> = []
            if pinned {
                blockers.insert(.pinned(version: pinnedVersion))
            }
            if autoUpdates == true {
                blockers.insert(.autoUpdates)
            }
            if version == nil {
                blockers.insert(.unavailable)
            } else if version == "latest" {
                blockers.insert(.latestVersion)
            }
            if disabled {
                blockers.insert(.disabled)
            }

            return HomebrewPackageMetadata(
                name: token,
                kind: .cask,
                upgradeEligibility: HomebrewPackageUpgradeEligibility(blockers: blockers)
            )
        }
    }

    private nonisolated enum CodingKeys: String, CodingKey {
        case formulae
        case casks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let formulae = try container.decode([Formula].self, forKey: .formulae)
        let casks = try container.decode([Cask].self, forKey: .casks)

        packages = formulae.map(\.metadata) + casks.map(\.metadata)
    }
}
