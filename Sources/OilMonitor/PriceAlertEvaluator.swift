import Foundation

final class PriceAlertEvaluator {

    private var upperArmed: [String: Bool] = [:]
    private var lowerArmed: [String: Bool] = [:]

    // Called at startup with cached price to establish baseline (no firing).
    func setBaseline(symbol: OilSymbol, price: Double, upperThreshold: Double, lowerThreshold: Double) {
        upperArmed[symbol.rawValue] = price < upperThreshold
        lowerArmed[symbol.rawValue] = price > lowerThreshold
    }

    // Called when the user modifies or enables a threshold.
    func resetArm(symbol: OilSymbol, currentPrice: Double, upperThreshold: Double, lowerThreshold: Double) {
        upperArmed[symbol.rawValue] = currentPrice < upperThreshold
        lowerArmed[symbol.rawValue] = currentPrice > lowerThreshold
    }

    func evaluate(
        symbol: OilSymbol,
        previousPrice: Double,
        currentPrice: Double,
        upperEnabled: Bool, upperThreshold: Double,
        lowerEnabled: Bool, lowerThreshold: Double,
        marketTime: Date
    ) -> [AlertFiring] {
        var results: [AlertFiring] = []
        let key = symbol.rawValue

        if upperEnabled && upperThreshold > 0 {
            let armed = upperArmed[key] ?? (previousPrice < upperThreshold)
            if armed && previousPrice < upperThreshold && currentPrice >= upperThreshold {
                upperArmed[key] = false
                results.append(AlertFiring(symbol: symbol, direction: .above,
                                           price: currentPrice, threshold: upperThreshold,
                                           marketTime: marketTime))
            } else if currentPrice < upperThreshold {
                upperArmed[key] = true
            }
        }

        if lowerEnabled && lowerThreshold > 0 {
            let armed = lowerArmed[key] ?? (previousPrice > lowerThreshold)
            if armed && previousPrice > lowerThreshold && currentPrice <= lowerThreshold {
                lowerArmed[key] = false
                results.append(AlertFiring(symbol: symbol, direction: .below,
                                           price: currentPrice, threshold: lowerThreshold,
                                           marketTime: marketTime))
            } else if currentPrice > lowerThreshold {
                lowerArmed[key] = true
            }
        }

        return results
    }
}
