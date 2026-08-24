import Foundation

nonisolated enum StatusMenuSection: CaseIterable, Hashable, Identifiable,
    Sendable
{
    case overview
    case updates

    var id: Self { self }

    var title: String {
        switch self {
        case .overview:
            "Overview"
        case .updates:
            "Updates"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            "gauge.with.dots.needle.50percent"
        case .updates:
            "arrow.down.circle"
        }
    }
}
