import Foundation

struct HomebrewOutdatedDataParser: Sendable {
    nonisolated func parse(_ output: String) throws -> HomebrewOutdatedData {
        try JSONDecoder().decode(
            HomebrewOutdatedData.self,
            from: Data(output.utf8)
        )
    }
}
