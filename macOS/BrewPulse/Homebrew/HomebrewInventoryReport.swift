import Foundation

struct HomebrewInventoryReport: Equatable, Sendable {
    let inventory: HomebrewInventory
    let commandResults: [CommandResult]
    let refreshedAt: Date
    let homebrewVersion: String?

    nonisolated init(
        inventory: HomebrewInventory,
        commandResults: [CommandResult],
        refreshedAt: Date,
        homebrewVersion: String? = nil
    ) {
        self.inventory = inventory
        self.commandResults = commandResults
        self.refreshedAt = refreshedAt
        self.homebrewVersion = homebrewVersion
    }
}
