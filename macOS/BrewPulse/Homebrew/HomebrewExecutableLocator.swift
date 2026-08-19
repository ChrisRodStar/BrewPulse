import Foundation

nonisolated struct HomebrewExecutableLocator: Sendable {
    static let candidatePaths = [
        "/opt/homebrew/bin/brew",
        "/usr/local/bin/brew",
        "/home/linuxbrew/.linuxbrew/bin/brew"
    ]

    private let isExecutableFile: @Sendable (String) -> Bool

    init(
        isExecutableFile: @escaping @Sendable (String) -> Bool = {
            FileManager.default.isExecutableFile(atPath: $0)
        }
    ) {
        self.isExecutableFile = isExecutableFile
    }

    func locate() -> URL? {
        guard let path = Self.candidatePaths.first(where: isExecutableFile) else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }
}
