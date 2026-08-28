import Foundation

nonisolated protocol AnalyticsHTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

nonisolated struct URLSessionAnalyticsTransport: AnalyticsHTTPTransport {
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieAcceptPolicy = .never
            configuration.httpShouldSetCookies = false
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            configuration.timeoutIntervalForRequest = 15
            self.session = URLSession(
                configuration: configuration,
                delegate: AnalyticsURLSessionDelegate(),
                delegateQueue: nil
            )
        }
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }
}

nonisolated private final class AnalyticsURLSessionDelegate:
    NSObject,
    URLSessionTaskDelegate,
    @unchecked Sendable
{
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

nonisolated struct AnalyticsClientMetadata: Sendable {
    let appVersion: String
    let macOSMajorVersion: Int
    let architecture: String

    static func current(bundle: Bundle = .main) -> AnalyticsClientMetadata {
        let version = bundle.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0.0"
#if arch(arm64)
        let architecture = "arm64"
#else
        let architecture = "x86_64"
#endif
        return AnalyticsClientMetadata(
            appVersion: version,
            macOSMajorVersion: ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
            architecture: architecture
        )
    }
}

@MainActor
final class BrewPulseAnalytics: AnalyticsTracking {
    private enum Key {
        static let installationID = "analytics.installationID"
        static let queue = "analytics.pendingEvents.v1"
        static let firstObservedInstallation =
            "analytics.brewPulseCloud.firstObservedInstallationReported.v1"
        static let activationCompleted =
            "analytics.brewPulseCloud.activationCompletedReported.v1"
    }

    private static let schemaVersion = 1
    private static let maximumQueueCount = 500
    private static let maximumBatchCount = 50
    private static let maximumRequestBytes = 64 * 1_024
    private static let maximumRetryDelay: TimeInterval = 6 * 60 * 60
    private static let healthRetryDelay: TimeInterval = 5 * 60
    private static let healthDeploymentVersion = "analytics-v1"

    private let endpoint: URL?
    private let healthEndpoint: URL?
    private let metadata: AnalyticsClientMetadata
    private let userDefaults: UserDefaults
    private let transport: any AnalyticsHTTPTransport
    private let automaticallyDelivers: Bool
    private var queue: [PendingAnalyticsEvent]
    private var isCollectionEnabled = false
    private var hasTrackedLaunch = false
    private var deliveryTask: Task<Void, Never>?
    private var isWaitingForRetry = false
    private var currentBatchLimit = maximumBatchCount

    var isConfigured: Bool {
        endpoint?.scheme == "https"
    }

    init(
        bundle: Bundle = .main,
        userDefaults: UserDefaults = .standard
    ) {
        let environment = ProcessInfo.processInfo.environment
        let isNonProductionRuntime =
            environment["XCTestConfigurationFilePath"] != nil ||
            environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        let environmentURL = environment[
            "BREWPULSE_ANALYTICS_INGESTION_URL"
        ]
        let configuredURL = isNonProductionRuntime
            ? nil
            : environmentURL ?? bundle.object(
                forInfoDictionaryKey: "BrewPulseAnalyticsIngestionURL"
            ) as? String
        let baseURL = configuredURL.flatMap {
            URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        self.endpoint = baseURL?.appending(
            path: "v1/analytics/events/batch",
            directoryHint: .notDirectory
        )
        self.healthEndpoint = baseURL?.appending(
            path: "v1/analytics/health",
            directoryHint: .notDirectory
        )
        self.metadata = .current(bundle: bundle)
        self.userDefaults = userDefaults
        self.transport = URLSessionAnalyticsTransport()
        self.automaticallyDelivers = true
        self.queue = Self.loadQueue(from: userDefaults)
    }

    init(
        endpoint: URL?,
        metadata: AnalyticsClientMetadata,
        userDefaults: UserDefaults,
        transport: any AnalyticsHTTPTransport,
        automaticallyDelivers: Bool
    ) {
        self.endpoint = endpoint?.appending(
            path: "v1/analytics/events/batch",
            directoryHint: .notDirectory
        )
        self.healthEndpoint = endpoint?.appending(
            path: "v1/analytics/health",
            directoryHint: .notDirectory
        )
        self.metadata = metadata
        self.userDefaults = userDefaults
        self.transport = transport
        self.automaticallyDelivers = automaticallyDelivers
        self.queue = Self.loadQueue(from: userDefaults)
    }

    func start(isEnabled: Bool) {
        isCollectionEnabled = isEnabled && isConfigured
        guard isCollectionEnabled else {
            if !isEnabled && isConfigured {
                deleteLocalAnalyticsState()
            }
            return
        }

        if !userDefaults.bool(forKey: Key.firstObservedInstallation) {
            track(.installationFirstObserved)
            userDefaults.set(true, forKey: Key.firstObservedInstallation)
        }
        if !hasTrackedLaunch {
            hasTrackedLaunch = true
            track(.appLaunched)
        }
        scheduleDelivery()
    }

    func setCollectionEnabled(_ isEnabled: Bool) {
        if !isEnabled {
            isCollectionEnabled = false
            deleteLocalAnalyticsState()
            return
        }
        start(isEnabled: true)
    }

    func track(_ event: AnalyticsEvent) {
        guard isCollectionEnabled else { return }
        queue.append(
            PendingAnalyticsEvent(
                schemaVersion: Self.schemaVersion,
                eventID: UUID().uuidString.lowercased(),
                occurredAt: Date(),
                appVersion: metadata.appVersion,
                macOSMajorVersion: metadata.macOSMajorVersion,
                architecture: metadata.architecture,
                name: event.name,
                parameters: event.parameters,
                attemptCount: 0,
                nextAttemptAt: Date()
            )
        )
        if queue.count > Self.maximumQueueCount {
            queue.removeFirst(queue.count - Self.maximumQueueCount)
        }
        saveQueue()
        if isWaitingForRetry {
            deliveryTask?.cancel()
            deliveryTask = nil
            isWaitingForRetry = false
        }
        scheduleDelivery()
    }

    func trackActivationIfNeeded() {
        guard isCollectionEnabled else { return }
        guard !userDefaults.bool(forKey: Key.activationCompleted) else { return }
        track(.activationCompleted)
        userDefaults.set(true, forKey: Key.activationCompleted)
    }

    func flushForTesting() async {
        await deliverNextBatch()
    }

    var pendingEventCountForTesting: Int {
        queue.count
    }

    private func scheduleDelivery() {
        guard automaticallyDelivers, deliveryTask == nil, isCollectionEnabled else {
            return
        }
        deliveryTask = Task { [weak self] in
            guard let self else { return }
            await self.runDeliveryLoop()
        }
    }

    private func runDeliveryLoop() async {
        defer { deliveryTask = nil }
        while isCollectionEnabled, !queue.isEmpty, !Task.isCancelled {
            if let nextAttemptAt = queue.map(\.nextAttemptAt).min(),
               nextAttemptAt > Date() {
                let delay = nextAttemptAt.timeIntervalSinceNow
                isWaitingForRetry = true
                try? await Task.sleep(for: .seconds(max(0, delay)))
                isWaitingForRetry = false
                if Task.isCancelled { return }
            }
            await deliverNextBatch()
        }
    }

    private func deliverNextBatch() async {
        guard isCollectionEnabled,
              let endpoint,
              let healthEndpoint,
              !queue.isEmpty else { return }
        let now = Date()
        let eligible = queue.filter { $0.nextAttemptAt <= now }
        guard !eligible.isEmpty else { return }
        let installationID = installationID()
        let batch = makeBatch(
            from: Array(eligible.prefix(currentBatchLimit)),
            installationID: installationID
        )
        guard !batch.events.isEmpty else {
            removeEvents(withIDs: [eligible[0].eventID])
            return
        }
        let eventIDs = batch.events.map(\.eventID)
        guard await isServiceHealthy(at: healthEndpoint) else {
            deferDelivery(eventIDs)
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = batch.data

        do {
            let (data, response) = try await transport.send(request)
            handle(
                statusCode: response.statusCode,
                headers: response.allHeaderFields,
                data: data,
                eventIDs: eventIDs
            )
        } catch {
            markForRetry(eventIDs, retryAfter: nil)
        }
    }

    private func isServiceHealthy(at endpoint: URL) async -> Bool {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await transport.send(request)
            guard response.statusCode == 200,
                  let health = try? Self.decoder.decode(
                      AnalyticsHealthResponse.self,
                      from: data
                  ) else { return false }
            return health.status == "ok" &&
                health.deploymentVersion == Self.healthDeploymentVersion &&
                health.schemaVersion == Self.schemaVersion
        } catch {
            return false
        }
    }

    private func makeBatch(
        from candidates: [PendingAnalyticsEvent],
        installationID: String
    ) -> (events: [PendingAnalyticsEvent], data: Data) {
        var events: [PendingAnalyticsEvent] = []
        var lastData = Data()
        for candidate in candidates {
            let proposed = events + [candidate]
            guard let data = try? Self.encoder.encode(
                AnalyticsBatch(installationID: installationID, events: proposed)
            ) else { continue }
            if data.count > Self.maximumRequestBytes {
                break
            }
            events = proposed
            lastData = data
        }
        return (events, lastData)
    }

    private func handle(
        statusCode: Int,
        headers: [AnyHashable: Any],
        data: Data,
        eventIDs: [String]
    ) {
        if statusCode == 408 || statusCode == 425 || statusCode == 429 ||
            (500...599).contains(statusCode) {
            markForRetry(eventIDs, retryAfter: retryAfter(headers: headers))
            return
        }

        if statusCode == 413 {
            if eventIDs.count == 1 {
                removeEvents(withIDs: eventIDs)
            } else {
                currentBatchLimit = max(1, eventIDs.count / 2)
            }
            return
        }

        guard let response = try? Self.decoder.decode(
            AnalyticsIngestionResponse.self,
            from: data
        ), response.schemaVersion == Self.schemaVersion else {
            removeEvents(withIDs: eventIDs)
            return
        }

        switch (statusCode, response.status) {
        case (202, "accepted"):
            guard Set(response.acceptedEventIDs) == Set(eventIDs) else {
                removeEvents(withIDs: eventIDs)
                return
            }
            removeEvents(withIDs: eventIDs)
            currentBatchLimit = Self.maximumBatchCount
        case (207, "partially_accepted"):
            let rejectedIDs = response.rejectedEvents.compactMap(\.eventID)
            removeEvents(withIDs: response.acceptedEventIDs + rejectedIDs)
            currentBatchLimit = Self.maximumBatchCount
        case (400...499, "rejected"):
            removeEvents(withIDs: eventIDs)
        default:
            removeEvents(withIDs: eventIDs)
        }
    }

    private func markForRetry(_ eventIDs: [String], retryAfter: TimeInterval?) {
        let identifiers = Set(eventIDs)
        let now = Date()
        for index in queue.indices where identifiers.contains(queue[index].eventID) {
            queue[index].attemptCount += 1
            let exponent = min(queue[index].attemptCount - 1, 12)
            let maximumDelay = min(
                Self.maximumRetryDelay,
                pow(2, Double(exponent + 1))
            )
            let delay = retryAfter ?? Double.random(in: 0...maximumDelay)
            queue[index].nextAttemptAt = now.addingTimeInterval(max(1, delay))
        }
        saveQueue()
    }

    private func deferDelivery(_ eventIDs: [String]) {
        let identifiers = Set(eventIDs)
        let nextCheck = Date().addingTimeInterval(Self.healthRetryDelay)
        for index in queue.indices where identifiers.contains(queue[index].eventID) {
            queue[index].nextAttemptAt = max(
                queue[index].nextAttemptAt,
                nextCheck
            )
        }
        saveQueue()
    }

    private func retryAfter(headers: [AnyHashable: Any]) -> TimeInterval? {
        for (key, value) in headers where
            String(describing: key).caseInsensitiveCompare("Retry-After") == .orderedSame {
            if let seconds = TimeInterval(String(describing: value)), seconds > 0 {
                return min(seconds, Self.maximumRetryDelay)
            }
        }
        return nil
    }

    private func installationID() -> String {
        if let existing = userDefaults.string(forKey: Key.installationID),
           UUID(uuidString: existing) != nil {
            return existing
        }
        let identifier = UUID().uuidString.lowercased()
        userDefaults.set(identifier, forKey: Key.installationID)
        return identifier
    }

    private func removeEvents(withIDs eventIDs: [String]) {
        let identifiers = Set(eventIDs)
        queue.removeAll { identifiers.contains($0.eventID) }
        saveQueue()
    }

    private func deleteLocalAnalyticsState() {
        deliveryTask?.cancel()
        deliveryTask = nil
        isWaitingForRetry = false
        queue.removeAll()
        userDefaults.removeObject(forKey: Key.queue)
        userDefaults.removeObject(forKey: Key.installationID)
        userDefaults.removeObject(forKey: Key.firstObservedInstallation)
        userDefaults.removeObject(forKey: Key.activationCompleted)
    }

    private func saveQueue() {
        if queue.isEmpty {
            userDefaults.removeObject(forKey: Key.queue)
        } else if let data = try? Self.encoder.encode(queue) {
            userDefaults.set(data, forKey: Key.queue)
        }
    }

    private static func loadQueue(from userDefaults: UserDefaults) -> [PendingAnalyticsEvent] {
        guard let data = userDefaults.data(forKey: Key.queue),
              let queue = try? decoder.decode([PendingAnalyticsEvent].self, from: data) else {
            return []
        }
        return Array(queue.suffix(maximumQueueCount))
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601WithMilliseconds
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = AnalyticsDateFormatter.date(from: value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid analytics timestamp."
                )
            }
            return date
        }
        return decoder
    }()
}

nonisolated private struct AnalyticsBatch: Encodable {
    let schemaVersion = 1
    let installationID: String
    let events: [AnalyticsWireEvent]

    init(installationID: String, events: [PendingAnalyticsEvent]) {
        self.installationID = installationID
        self.events = events.map(AnalyticsWireEvent.init)
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case installationID = "installation_id"
        case events
    }
}

nonisolated private struct PendingAnalyticsEvent: Codable, Sendable {
    let schemaVersion: Int
    let eventID: String
    let occurredAt: Date
    let appVersion: String
    let macOSMajorVersion: Int
    let architecture: String
    let name: String
    let parameters: [String: String]
    var attemptCount: Int
    var nextAttemptAt: Date

}

nonisolated private struct AnalyticsWireEvent: Encodable {
    let schemaVersion: Int
    let eventID: String
    let occurredAt: Date
    let appVersion: String
    let macOSMajorVersion: Int
    let architecture: String
    let name: String
    let parameters: [String: String]

    init(_ pending: PendingAnalyticsEvent) {
        schemaVersion = pending.schemaVersion
        eventID = pending.eventID
        occurredAt = pending.occurredAt
        appVersion = pending.appVersion
        macOSMajorVersion = pending.macOSMajorVersion
        architecture = pending.architecture
        name = pending.name
        parameters = pending.parameters
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case eventID = "event_id"
        case occurredAt = "occurred_at"
        case appVersion = "app_version"
        case macOSMajorVersion = "macos_major_version"
        case architecture
        case name
        case parameters
    }
}

nonisolated private struct AnalyticsIngestionResponse: Decodable {
    let schemaVersion: Int
    let status: String
    let acceptedEventIDs: [String]
    let rejectedEvents: [RejectedAnalyticsEvent]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case status
        case acceptedEventIDs = "accepted_event_ids"
        case rejectedEvents = "rejected_events"
    }
}

nonisolated private struct AnalyticsHealthResponse: Decodable {
    let status: String
    let deploymentVersion: String
    let schemaVersion: Int

    enum CodingKeys: String, CodingKey {
        case status
        case deploymentVersion = "deployment_version"
        case schemaVersion = "schema_version"
    }
}

nonisolated private struct RejectedAnalyticsEvent: Decodable {
    let eventID: String?

    enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
    }
}

nonisolated private extension JSONEncoder.DateEncodingStrategy {
    static let iso8601WithMilliseconds = custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(AnalyticsDateFormatter.string(from: date))
    }
}

nonisolated private enum AnalyticsDateFormatter {
    static func string(from date: Date) -> String {
        let seconds = floor(date.timeIntervalSince1970)
        let milliseconds = Int((date.timeIntervalSince1970 - seconds) * 1_000)
        let base = ISO8601DateFormatter().string(
            from: Date(timeIntervalSince1970: seconds)
        ).replacingOccurrences(of: "Z", with: "")
        return String(format: "%@.%03dZ", base, milliseconds)
    }

    static func date(from string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter.date(from: string)
    }
}
