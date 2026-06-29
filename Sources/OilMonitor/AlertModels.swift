import Foundation

enum AlertDirection {
    case above, below
}

struct AlertFiring {
    let symbol: OilSymbol
    let direction: AlertDirection
    let price: Double
    let threshold: Double
    let marketTime: Date

    var notificationTitle: String {
        let dir = direction == .above ? "突破上限" : "跌破下限"
        return "\(symbol.displayName) 价格\(dir)"
    }

    var notificationBody: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return String(format: "当前 $%.2f，阈值 $%.2f（行情 %@）",
                      price, threshold, fmt.string(from: marketTime))
    }
}
