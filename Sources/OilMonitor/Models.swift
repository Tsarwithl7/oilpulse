import Foundation

struct OilPrice: Identifiable {
    let id: UUID
    let symbol: String
    let name: String
    let price: Double
    let currency: String
    let change: Double
    let changePercent: Double
    let marketTime: Date
    let source: String

    var isUp: Bool { change > 0 }
    var isDown: Bool { change < 0 }
}

struct PricePoint: Identifiable {
    let id = UUID()
    let symbol: String
    let price: Double
    let marketTime: Date
}

enum OilSymbol: String, CaseIterable {
    case brent    = "BZ=F"
    case wti      = "CL=F"
    case gasoline = "RB=F"

    var displayName: String {
        switch self {
        case .brent:    return "Brent"
        case .wti:      return "WTI"
        case .gasoline: return "RBOB"
        }
    }

    var unit: String {
        switch self {
        case .brent, .wti: return "USD / barrel"
        case .gasoline:    return "USD / gallon"
        }
    }
}

enum TimeRange: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"

    var yahooInterval: String {
        switch self {
        case .oneDay: return "5m"
        case .oneWeek: return "30m"
        case .oneMonth: return "1d"
        }
    }

    var yahooRange: String {
        switch self {
        case .oneDay: return "1d"
        case .oneWeek: return "5d"
        case .oneMonth: return "1mo"
        }
    }

    var historyLookback: TimeInterval {
        switch self {
        case .oneDay: return 86400
        case .oneWeek: return 7 * 86400
        case .oneMonth: return 30 * 86400
        }
    }
}

enum DataStatus: Equatable {
    case loading
    case normal
    case cached
    case offline
    case failed(String)
    case noData
}
