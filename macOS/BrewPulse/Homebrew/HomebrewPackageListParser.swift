import Foundation

struct HomebrewPackageListParser: Sendable {
    nonisolated func parse(
        _ output: String,
        kind: HomebrewPackage.Kind
    ) -> [HomebrewPackage] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let fields = line.split(whereSeparator: \.isWhitespace)
                guard let name = fields.first else { return nil }

                return HomebrewPackage(
                    name: String(name),
                    versions: HomebrewPackageVersions(
                        installed: fields.dropFirst().map(String.init)
                    ),
                    kind: kind
                )
            }
            .sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }
}
