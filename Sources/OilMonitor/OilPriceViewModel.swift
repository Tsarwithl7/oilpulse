import Foundation
import SwiftUI

@MainActor
final class OilPriceViewModel: ObservableObject {

    // MARK: - Published State

    @Published var brentPrice: OilPrice?
    @Published var wtiPrice: OilPrice?
    @Published var gasolinePrice: OilPrice?
    @Published var brentHistory: [PricePoint] = []
    @Published var wtiHistory: [PricePoint] = []
    @Published var gasolineHistory: [PricePoint] = []
    @Published var isRefreshing = false
    @Published var isForceRefreshing = false
    @Published var dataStatus: DataStatus = .loading
    @Published var errorMessage: String?
    @Published var selectedSymbol: OilSymbol = .brent
    @Published var selectedRange: TimeRange = .oneDay
    @Published var lastRefreshedAt: Date?

    // MARK: - Settings

    @AppStorage("refreshIntervalMinutes") var refreshIntervalMinutes: Int = 30
    @AppStorage("showPriceInMenuBar") var showPriceInMenuBar: Bool = true

    // MARK: - Private

    private let service = YahooFinanceService()
    private let database = DatabaseService()
    private var normalRefreshTask: Task<Void, Never>?
    private var forceRefreshTask: Task<Void, Never>?
    private var timer: Timer?
    private var lastNormalRefreshAt: Date?
    private let normalCooldown: TimeInterval = 10

    // MARK: - Alert

    private let evaluator = PriceAlertEvaluator()
    private let notifications = NotificationService.shared
    private var previousBrentPrice: Double?
    private var previousWtiPrice: Double?
    private var previousGasolinePrice: Double?

    private var brentAlertCfg: (upperEnabled: Bool, upper: Double, lowerEnabled: Bool, lower: Double) {
        let ud = UserDefaults.standard
        return (ud.bool(forKey: "brentUpperAlertEnabled"),
                ud.double(forKey: "brentUpperAlertThreshold"),
                ud.bool(forKey: "brentLowerAlertEnabled"),
                ud.double(forKey: "brentLowerAlertThreshold"))
    }

    private var wtiAlertCfg: (upperEnabled: Bool, upper: Double, lowerEnabled: Bool, lower: Double) {
        let ud = UserDefaults.standard
        return (ud.bool(forKey: "wtiUpperAlertEnabled"),
                ud.double(forKey: "wtiUpperAlertThreshold"),
                ud.bool(forKey: "wtiLowerAlertEnabled"),
                ud.double(forKey: "wtiLowerAlertThreshold"))
    }

    private var gasolineAlertCfg: (upperEnabled: Bool, upper: Double, lowerEnabled: Bool, lower: Double) {
        let ud = UserDefaults.standard
        return (ud.bool(forKey: "gasolineUpperAlertEnabled"),
                ud.double(forKey: "gasolineUpperAlertThreshold"),
                ud.bool(forKey: "gasolineLowerAlertEnabled"),
                ud.double(forKey: "gasolineLowerAlertThreshold"))
    }

    var enabledAlertCount: Int {
        let ud = UserDefaults.standard
        return [
            "brentUpperAlertEnabled",    "brentLowerAlertEnabled",
            "wtiUpperAlertEnabled",      "wtiLowerAlertEnabled",
            "gasolineUpperAlertEnabled", "gasolineLowerAlertEnabled"
        ].filter { ud.bool(forKey: $0) }.count
    }

    func resetAlertBaseline(for symbol: OilSymbol) {
        switch symbol {
        case .brent:
            guard let price = brentPrice?.price else { return }
            let c = brentAlertCfg
            evaluator.resetArm(symbol: .brent, currentPrice: price,
                               upperThreshold: c.upper, lowerThreshold: c.lower)
        case .wti:
            guard let price = wtiPrice?.price else { return }
            let c = wtiAlertCfg
            evaluator.resetArm(symbol: .wti, currentPrice: price,
                               upperThreshold: c.upper, lowerThreshold: c.lower)
        case .gasoline:
            guard let price = gasolinePrice?.price else { return }
            let c = gasolineAlertCfg
            evaluator.resetArm(symbol: .gasoline, currentPrice: price,
                               upperThreshold: c.upper, lowerThreshold: c.lower)
        }
    }

    private func evaluateAlerts(brent: OilPrice, wti: OilPrice, gasoline: OilPrice) {
        var firings: [AlertFiring] = []
        let bc = brentAlertCfg
        let wc = wtiAlertCfg
        let gc = gasolineAlertCfg

        if let prev = previousBrentPrice {
            firings += evaluator.evaluate(
                symbol: .brent,
                previousPrice: prev, currentPrice: brent.price,
                upperEnabled: bc.upperEnabled, upperThreshold: bc.upper,
                lowerEnabled: bc.lowerEnabled, lowerThreshold: bc.lower,
                marketTime: brent.marketTime)
        }
        previousBrentPrice = brent.price

        if let prev = previousWtiPrice {
            firings += evaluator.evaluate(
                symbol: .wti,
                previousPrice: prev, currentPrice: wti.price,
                upperEnabled: wc.upperEnabled, upperThreshold: wc.upper,
                lowerEnabled: wc.lowerEnabled, lowerThreshold: wc.lower,
                marketTime: wti.marketTime)
        }
        previousWtiPrice = wti.price

        if let prev = previousGasolinePrice {
            firings += evaluator.evaluate(
                symbol: .gasoline,
                previousPrice: prev, currentPrice: gasoline.price,
                upperEnabled: gc.upperEnabled, upperThreshold: gc.upper,
                lowerEnabled: gc.lowerEnabled, lowerThreshold: gc.lower,
                marketTime: gasoline.marketTime)
        }
        previousGasolinePrice = gasoline.price

        // 请求权限（首次有提醒启用时），然后发送通知
        if !firings.isEmpty {
            Task {
                if notifications.authorizationStatus == .notDetermined {
                    _ = await notifications.requestPermission()
                }
                for f in firings { notifications.send(f) }
            }
        }
    }

    // MARK: - Init

    init() {
        Task {
            await loadFromCache()
            await performFetch()
        }
        scheduleTimer()
    }

    // MARK: - Cache

    private func loadFromCache() async {
        let b = await database.loadLatestPrice(for: OilSymbol.brent.rawValue)
        let w = await database.loadLatestPrice(for: OilSymbol.wti.rawValue)
        let g = await database.loadLatestPrice(for: OilSymbol.gasoline.rawValue)
        brentPrice = b
        wtiPrice = w
        gasolinePrice = g

        if let b = b {
            let c = brentAlertCfg
            evaluator.setBaseline(symbol: .brent, price: b.price,
                                  upperThreshold: c.upper, lowerThreshold: c.lower)
            previousBrentPrice = b.price
        }
        if let w = w {
            let c = wtiAlertCfg
            evaluator.setBaseline(symbol: .wti, price: w.price,
                                  upperThreshold: c.upper, lowerThreshold: c.lower)
            previousWtiPrice = w.price
        }
        if let g = g {
            let c = gasolineAlertCfg
            evaluator.setBaseline(symbol: .gasoline, price: g.price,
                                  upperThreshold: c.upper, lowerThreshold: c.lower)
            previousGasolinePrice = g.price
        }

        dataStatus = (b != nil || w != nil || g != nil) ? .cached : .noData
        await refreshHistoryFromCache()
    }

    private func refreshHistoryFromCache() async {
        let bh = await database.loadPriceHistory(for: OilSymbol.brent.rawValue, range: selectedRange)
        let wh = await database.loadPriceHistory(for: OilSymbol.wti.rawValue, range: selectedRange)
        let gh = await database.loadPriceHistory(for: OilSymbol.gasoline.rawValue, range: selectedRange)
        brentHistory = bh
        wtiHistory = wh
        gasolineHistory = gh
    }

    // MARK: - Panel Opened

    func panelOpened() {
        if let t = normalRefreshTask, !t.isCancelled { return }
        normalRefreshTask = Task { await performFetch() }
    }

    // MARK: - Normal Refresh

    func refresh() {
        if isForceRefreshing { return }
        if let last = lastNormalRefreshAt, Date().timeIntervalSince(last) < normalCooldown { return }
        if let t = normalRefreshTask, !t.isCancelled { return }
        normalRefreshTask = Task { await performFetch() }
    }

    private func performFetch() async {
        guard !isForceRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        do {
            async let bFetch = service.fetchCurrentPrice(for: .brent)
            async let wFetch = service.fetchCurrentPrice(for: .wti)
            async let gFetch = service.fetchCurrentPrice(for: .gasoline)
            let (b, w, g) = try await (bFetch, wFetch, gFetch)

            evaluateAlerts(brent: b, wti: w, gasoline: g)
            brentPrice = b
            wtiPrice = w
            gasolinePrice = g
            await database.saveLatestPrice(b)
            await database.saveLatestPrice(w)
            await database.saveLatestPrice(g)

            await fetchAndSaveHistory()

            lastNormalRefreshAt = Date()
            lastRefreshedAt = Date()
            dataStatus = .normal
        } catch {
            errorMessage = error.localizedDescription
            dataStatus = (brentPrice != nil || wtiPrice != nil || gasolinePrice != nil) ? .cached : .offline
        }

        isRefreshing = false
    }

    // MARK: - Force Refresh

    func forceRefresh() {
        if let t = forceRefreshTask, !t.isCancelled { return }
        normalRefreshTask?.cancel()
        normalRefreshTask = nil
        forceRefreshTask = Task { await performForceRefresh() }
    }

    private func performForceRefresh() async {
        isRefreshing = true
        isForceRefreshing = true
        errorMessage = nil

        do {
            async let bFetch = service.fetchCurrentPrice(for: .brent)
            async let wFetch = service.fetchCurrentPrice(for: .wti)
            async let gFetch = service.fetchCurrentPrice(for: .gasoline)
            let (b, w, g) = try await (bFetch, wFetch, gFetch)

            evaluateAlerts(brent: b, wti: w, gasoline: g)
            brentPrice = b
            wtiPrice = w
            gasolinePrice = g
            await database.saveLatestPrice(b)
            await database.saveLatestPrice(w)
            await database.saveLatestPrice(g)

            await fetchAndSaveHistory()

            lastNormalRefreshAt = Date()
            lastRefreshedAt = Date()
            dataStatus = .normal
        } catch {
            errorMessage = error.localizedDescription
            dataStatus = (brentPrice != nil || wtiPrice != nil || gasolinePrice != nil) ? .cached : .offline
        }

        isRefreshing = false
        isForceRefreshing = false
        forceRefreshTask = nil
    }

    // MARK: - History

    private func fetchAndSaveHistory() async {
        do {
            async let bh = service.fetchHistory(for: .brent, range: selectedRange)
            async let wh = service.fetchHistory(for: .wti, range: selectedRange)
            async let gh = service.fetchHistory(for: .gasoline, range: selectedRange)
            let (b, w, g) = try await (bh, wh, gh)
            brentHistory = b
            wtiHistory = w
            gasolineHistory = g
            await database.savePriceHistory(b)
            await database.savePriceHistory(w)
            await database.savePriceHistory(g)
        } catch {
            await refreshHistoryFromCache()
        }
    }

    func changeRange(_ range: TimeRange) {
        selectedRange = range
        Task {
            await refreshHistoryFromCache()
            await fetchAndSaveHistory()
        }
    }

    // MARK: - Timer

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(refreshIntervalMinutes * 60),
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.normalRefreshTask = Task { await self.performFetch() } }
        }
    }

    func updateTimerInterval() { scheduleTimer() }

    // MARK: - Computed

    var currentHistory: [PricePoint] {
        switch selectedSymbol {
        case .brent:    return brentHistory
        case .wti:      return wtiHistory
        case .gasoline: return gasolineHistory
        }
    }

    var menuBarText: String? {
        guard showPriceInMenuBar, let b = brentPrice, let w = wtiPrice else { return nil }
        if let g = gasolinePrice {
            return String(format: "B %.2f · W %.2f · G %.2f", b.price, w.price, g.price)
        }
        return String(format: "B %.2f · W %.2f", b.price, w.price)
    }

    var lastUpdatedText: String {
        guard let t = lastRefreshedAt else { return "尚未刷新" }
        let diff = Date().timeIntervalSince(t)
        if diff < 60 { return "刚刚更新" }
        if diff < 3600 { return "\(Int(diff / 60)) 分钟前" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: t)
    }

    var marketTimeText: String? {
        let ref = brentPrice?.marketTime ?? wtiPrice?.marketTime
        guard let t = ref else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d HH:mm"
        return "行情 " + fmt.string(from: t)
    }
}
