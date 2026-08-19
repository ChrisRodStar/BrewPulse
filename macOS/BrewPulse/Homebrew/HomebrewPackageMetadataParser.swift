import Foundation

struct HomebrewPackageMetadataParser: Sendable {
    nonisolated func parse(_ output: String) throws -> HomebrewPackageMetadataData {
        try JSONDecoder().decode(
            HomebrewPackageMetadataData.self,
            from: Data(output.utf8)
        )
    }
}
