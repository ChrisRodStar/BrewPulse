import Foundation

nonisolated enum StatusMenuSection: CaseIterable, Hashable, Identifiable,
    Sendable
{
    case status
    case casks
    case formulae

    var id: Self { self }

    var title: String {
        switch self {
        case .status:
            "Status"
        case .casks:
            "Casks"
        case .formulae:
            "Formulae"
        }
    }

    var systemImage: String {
        switch self {
        case .status:
            "gauge.with.dots.needle.50percent"
        case .casks:
            "macwindow"
        case .formulae:
            "shippingbox"
        }
    }
}
