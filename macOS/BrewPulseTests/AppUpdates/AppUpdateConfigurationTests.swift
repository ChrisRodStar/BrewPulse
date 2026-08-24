import Foundation
import Testing

@Suite("App update configuration")
struct AppUpdateConfigurationTests {
    private let bundle = Bundle(identifier: "com.chrisrodstar.BrewPulse")

    @Test("Checks automatically but asks before installing")
    func automaticCheckPolicy() throws {
        let bundle = try #require(bundle)

        #expect(bundle.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool == true)
        #expect(bundle.object(forInfoDictionaryKey: "SUAutomaticallyUpdate") as? Bool == false)
    }

    @Test("Uses a secure signed update feed")
    func signedFeed() throws {
        let bundle = try #require(bundle)
        let feed = try #require(
            bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        )
        let feedURL = try #require(URL(string: feed))
        let publicKey = try #require(
            bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        )

        #expect(feedURL.scheme == "https")
        #expect(feedURL.host == "raw.githubusercontent.com")
        #expect(!publicKey.isEmpty)
        #expect(bundle.object(forInfoDictionaryKey: "SURequireSignedFeed") as? Bool == true)
        #expect(bundle.object(forInfoDictionaryKey: "SUVerifyUpdateBeforeExtraction") as? Bool == true)
    }
}
