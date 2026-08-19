import Foundation

enum FixtureLoaderError: Error {
    case missingFixture(String)
}

enum FixtureLoader {
    static func text(
        named name: String,
        fileExtension: String = "txt"
    ) throws -> String {
        let bundle = Bundle(for: FixtureBundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
            throw FixtureLoaderError.missingFixture(name)
        }

        return String(decoding: try Data(contentsOf: url), as: UTF8.self)
    }
}

private final class FixtureBundleToken {}
