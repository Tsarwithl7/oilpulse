import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var vm: OilPriceViewModel
    @State private var showSettings = false
    @State private var showStrategy = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────────────
            HStack {
                Text("Oil Monitor")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(spacing: 4) {
                        if vm.isRefreshing {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                        }
                        Text(vm.lastUpdatedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let market = vm.marketTimeText {
                        Text(market)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // ── Price cards ─────────────────────────────────────────────
            HStack(spacing: 0) {
                if let b = vm.brentPrice {
                    PriceCardView(price: b)
                } else {
                    EmptyPriceCardView(name: "Brent", unit: OilSymbol.brent.unit)
                }

                Divider()

                if let w = vm.wtiPrice {
                    PriceCardView(price: w)
                } else {
                    EmptyPriceCardView(name: "WTI", unit: OilSymbol.wti.unit)
                }

                Divider()

                if let g = vm.gasolinePrice {
                    PriceCardView(price: g)
                } else {
                    EmptyPriceCardView(name: "RBOB", unit: OilSymbol.gasoline.unit)
                }
            }

            Divider()

            // ── Chart symbol selector ────────────────────────────────────
            HStack(spacing: 4) {
                ForEach(OilSymbol.allCases, id: \.self) { sym in
                    Button(sym.displayName) {
                        vm.selectedSymbol = sym
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .fontWeight(vm.selectedSymbol == sym ? .semibold : .regular)
                    .foregroundStyle(vm.selectedSymbol == sym ? Color.primary : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        vm.selectedSymbol == sym
                            ? Color.secondary.opacity(0.15)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 4)
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            // ── Chart ────────────────────────────────────────────────────
            ChartView(points: vm.currentHistory, range: vm.selectedRange)
                .frame(height: 130)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

            // ── Time range selector ──────────────────────────────────────
            HStack {
                Spacer()
                ForEach(TimeRange.allCases, id: \.self) { r in
                    Button(r.rawValue) {
                        vm.changeRange(r)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: vm.selectedRange == r ? .semibold : .regular))
                    .foregroundStyle(vm.selectedRange == r ? Color.accentColor : Color.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        vm.selectedRange == r
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 5)
                    )
                }
                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            // ── Status bar ───────────────────────────────────────────────
            StatusBarView(vm: vm, showSettings: $showSettings, showStrategy: $showStrategy)
        }
        .frame(width: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(vm)
        }
        .sheet(isPresented: $showStrategy) {
            StrategyView()
                .environmentObject(vm)
        }
    }
}
