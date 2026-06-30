import Foundation

// MARK: - Enums

enum StrategyRecommendation: String, Codable {
    case fillNow = "fill_now"
    case wait    = "wait"
    case neutral = "neutral"

    var displayText: String {
        switch self {
        case .fillNow:  return "建议现在加油"
        case .wait:     return "建议再等等"
        case .neutral:  return "暂不明朗"
        }
    }

    var color: String {
        switch self {
        case .fillNow:  return "green"
        case .wait:     return "orange"
        case .neutral:  return "secondary"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = StrategyRecommendation(rawValue: raw) ?? .neutral
    }
}

enum StrategyConfidence: String, Codable {
    case low, medium, high

    var displayText: String {
        switch self {
        case .low:    return "低"
        case .medium: return "中"
        case .high:   return "高"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = StrategyConfidence(rawValue: raw) ?? .low
    }
}

enum TrendDirection: String, Codable {
    case rising, falling, stable

    var displayText: String {
        switch self {
        case .rising:  return "上涨"
        case .falling: return "下跌"
        case .stable:  return "平稳"
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TrendDirection(rawValue: raw) ?? .stable
    }
}

// MARK: - Signals (computed locally, sent to LLM)

struct LocalSignals {
    let asOf: Date
    let windowDays: Int
    let dataPointCount: Int

    // Momentum over the window (nil = insufficient data)
    let brentMomentumPct: Double?
    let wtiMomentumPct: Double?
    let rbobMomentumPct: Double?
    let rbobShortMomentumPct: Double?  // 5-day acceleration indicator

    // Crude→RBOB lead-lag (Pearson r; nil = insufficient data)
    let crudeRbobLeadLagCorr: Double?
    let leadLagDays: Int

    // Crack-spread proxy = RBOB*42 - WTI ($/barrel comparable)
    let crackSpreadProxy: Double?
    let crackSpreadChange: Double?

    // Vehicle profile (from user settings)
    let tankGallons: Double
    let weeklyMiles: Double
    let mpg: Double

    var weeklyFuelGallons: Double { mpg > 0 ? weeklyMiles / mpg : 0 }
}

// MARK: - LLM Response (strict JSON schema)

struct LLMStrategyResponse: Codable {
    let recommendation: StrategyRecommendation
    let confidence: StrategyConfidence
    let trend: TrendDirection
    let outlook: String
    let reasoning: String
    let estimatedPriceChangePct: Double
}

// MARK: - Cached Plan

struct StrategyPlan: Codable, Equatable {
    let recommendation: StrategyRecommendation
    let confidence: StrategyConfidence
    let trend: TrendDirection
    let outlook: String
    let reasoning: String
    let estimatedPriceChangePct: Double
    let generatedAt: Date
    let modelName: String
}
