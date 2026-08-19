nonisolated struct HomebrewPackageUpgradeEligibility: Equatable, Sendable {
    nonisolated enum Blocker: Hashable, Sendable {
        case pinned(version: String?)
        case autoUpdates
        case latestVersion
        case disabled
        case unavailable
        case metadataUnavailable
    }

    let blockers: Set<Blocker>

    init(blockers: Set<Blocker> = []) {
        self.blockers = blockers
    }

    var allowsStandardUpgrade: Bool { blockers.isEmpty }

    func merging(
        _ other: HomebrewPackageUpgradeEligibility
    ) -> HomebrewPackageUpgradeEligibility {
        let preferredPinnedBlocker = other.pinnedBlocker ?? pinnedBlocker
        var mergedBlockers = blockers.union(other.blockers)
        mergedBlockers = Set(mergedBlockers.filter { !$0.isPinned })
        if let preferredPinnedBlocker {
            mergedBlockers.insert(preferredPinnedBlocker)
        }

        return HomebrewPackageUpgradeEligibility(blockers: mergedBlockers)
    }

    private var pinnedBlocker: Blocker? {
        blockers.first(where: \.isPinned)
    }
}

private extension HomebrewPackageUpgradeEligibility.Blocker {
    nonisolated var isPinned: Bool {
        if case .pinned = self { true } else { false }
    }
}
