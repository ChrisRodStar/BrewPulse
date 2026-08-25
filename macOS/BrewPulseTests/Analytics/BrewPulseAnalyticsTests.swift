import Foundation
import Testing
@testable import BrewPulse

@Suite("BrewPulse analytics")
@MainActor
struct BrewPulseAnalyticsTests {
    @Test("Sends the approved launch events and removes accepted events")
    func sendsApprovedLaunchEvents() async throws {
        let defaults = try testDefaults()
        let transport = StubAnalyticsTransport(results: [.accepted])
        let analytics = makeAnalytics(defaults: defaults, transport: transport)

        analytics.start(isEnabled: true)
        #expect(analytics.pendingEventCountForTesting == 2)

        await analytics.flushForTesting()

        #expect(analytics.pendingEventCountForTesting == 0)
        let request = try #require(transport.firstRequest())
        #expect(
            request.url?.absoluteString ==
                "https://example.com/v1/analytics/events/batch"
        )
        let payload = try requestPayload(request)
        #expect(payload["schema_version"] as? Int == 1)
        #expect((payload["installation_id"] as? String).flatMap(UUID.init) != nil)
        let events = try #require(payload["events"] as? [[String: Any]])
        #expect(events.map { $0["name"] as? String } == [
            "BrewPulse.Installation.firstObserved",
            "BrewPulse.App.launched"
        ])
        #expect(events.allSatisfy { $0["attemptCount"] == nil })
        #expect(events.allSatisfy { $0["nextAttemptAt"] == nil })
    }

    @Test("Persists stable events after a transient delivery failure")
    func persistsTransientFailures() async throws {
        let defaults = try testDefaults()
        let transport = StubAnalyticsTransport(results: [.failure])
        let analytics = makeAnalytics(defaults: defaults, transport: transport)
        analytics.start(isEnabled: true)

        await analytics.flushForTesting()
        #expect(analytics.pendingEventCountForTesting == 2)

        let restored = makeAnalytics(
            defaults: defaults,
            transport: StubAnalyticsTransport(results: [])
        )
        #expect(restored.pendingEventCountForTesting == 2)
    }

    @Test("Opting out deletes queued events and the installation identifier")
    func optOutDeletesLocalState() async throws {
        let defaults = try testDefaults()
        let transport = StubAnalyticsTransport(results: [.accepted])
        let analytics = makeAnalytics(defaults: defaults, transport: transport)
        analytics.start(isEnabled: true)
        await analytics.flushForTesting()
        analytics.track(.menuOpened)
        #expect(defaults.string(forKey: "analytics.installationID") != nil)
        #expect(analytics.pendingEventCountForTesting == 1)

        analytics.setCollectionEnabled(false)

        #expect(analytics.pendingEventCountForTesting == 0)
        #expect(defaults.string(forKey: "analytics.installationID") == nil)
        #expect(defaults.data(forKey: "analytics.pendingEvents.v1") == nil)
    }

    @Test("An unconfigured build remains disabled")
    func unconfiguredBuildIsDisabled() throws {
        let defaults = try testDefaults()
        let analytics = BrewPulseAnalytics(
            endpoint: nil,
            metadata: testMetadata,
            userDefaults: defaults,
            transport: StubAnalyticsTransport(results: []),
            automaticallyDelivers: false
        )

        analytics.start(isEnabled: true)

        #expect(!analytics.isConfigured)
        #expect(analytics.pendingEventCountForTesting == 0)
    }

    @Test("Bounds the persistent queue and batches delivery")
    func boundsAndBatches() async throws {
        let defaults = try testDefaults()
        let transport = StubAnalyticsTransport(results: [.accepted, .accepted])
        let analytics = makeAnalytics(defaults: defaults, transport: transport)
        analytics.start(isEnabled: true)
        for _ in 0..<510 {
            analytics.track(.menuOpened)
        }
        #expect(analytics.pendingEventCountForTesting == 500)

        await analytics.flushForTesting()
        await analytics.flushForTesting()

        let requests = transport.allRequests()
        #expect(requests.count == 2)
        let firstEvents = try #require(
            requestPayload(requests[0])["events"] as? [[String: Any]]
        )
        let secondEvents = try #require(
            requestPayload(requests[1])["events"] as? [[String: Any]]
        )
        #expect(firstEvents.count == 50)
        #expect(secondEvents.count == 50)
        #expect(analytics.pendingEventCountForTesting == 400)
    }

    @Test("Keeps event identifiers stable for retry and drops malformed responses")
    func stableRetryAndMalformedResponse() async throws {
        let defaults = try testDefaults()
        let failingTransport = StubAnalyticsTransport(results: [.failure])
        let analytics = makeAnalytics(
            defaults: defaults,
            transport: failingTransport
        )
        analytics.start(isEnabled: true)
        await analytics.flushForTesting()
        let failedRequest = try #require(failingTransport.firstRequest())
        let failedPayload = try requestPayload(failedRequest)
        let sentEvents = try #require(
            failedPayload["events"] as? [[String: Any]]
        )
        let sentIdentifiers = sentEvents.compactMap { $0["event_id"] as? String }
        let persistedData = try #require(
            defaults.data(forKey: "analytics.pendingEvents.v1")
        )
        let persisted = try #require(
            JSONSerialization.jsonObject(with: persistedData) as? [[String: Any]]
        )
        #expect(persisted.compactMap { $0["eventID"] as? String } == sentIdentifiers)

        let malformed = makeAnalytics(
            defaults: defaults,
            transport: StubAnalyticsTransport(results: [.malformed])
        )
        malformed.track(.menuOpened)
        malformed.start(isEnabled: true)
        // The retried events are intentionally delayed; the new launch is eligible now.
        await malformed.flushForTesting()
        #expect(malformed.pendingEventCountForTesting == 2)
    }

    private var testMetadata: AnalyticsClientMetadata {
        AnalyticsClientMetadata(
            appVersion: "0.2.4",
            macOSMajorVersion: 27,
            architecture: "arm64"
        )
    }

    private func makeAnalytics(
        defaults: UserDefaults,
        transport: StubAnalyticsTransport
    ) -> BrewPulseAnalytics {
        BrewPulseAnalytics(
            endpoint: URL(string: "https://example.com"),
            metadata: testMetadata,
            userDefaults: defaults,
            transport: transport,
            automaticallyDelivers: false
        )
    }

    private func testDefaults() throws -> UserDefaults {
        let suiteName = "BrewPulseAnalyticsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func requestPayload(_ request: URLRequest) throws -> [String: Any] {
        let data = try #require(request.httpBody)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }
}

nonisolated private enum StubAnalyticsResult: Sendable {
    case accepted
    case failure
    case malformed
}

nonisolated private final class StubAnalyticsTransport:
    AnalyticsHTTPTransport,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var results: [StubAnalyticsResult]
    private var requests: [URLRequest] = []

    init(results: [StubAnalyticsResult]) {
        self.results = results
    }

    func firstRequest() -> URLRequest? {
        lock.withLock { requests.first }
    }

    func allRequests() -> [URLRequest] {
        lock.withLock { requests }
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let result = lock.withLock { () -> StubAnalyticsResult in
            requests.append(request)
            return results.isEmpty ? .failure : results.removeFirst()
        }
        switch result {
        case .failure:
            throw URLError(.notConnectedToInternet)
        case .malformed:
            return (
                Data("not-json".utf8),
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 202,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        case .accepted:
            let payload = try JSONSerialization.jsonObject(
                with: request.httpBody ?? Data()
            ) as? [String: Any]
            let events = payload?["events"] as? [[String: Any]] ?? []
            let identifiers = events.compactMap { $0["event_id"] as? String }
            let responseBody: [String: Any] = [
                "schema_version": 1,
                "status": "accepted",
                "accepted_event_ids": identifiers,
                "rejected_events": []
            ]
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 202,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                try JSONSerialization.data(withJSONObject: responseBody),
                response
            )
        }
    }
}
