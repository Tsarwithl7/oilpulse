import SwiftUI

struct PriceCardView: View {
    let price: OilPrice

    private var changeColor: Color {
        price.isUp ? .green : (price.isDown ? .red : .secondary)
    }

    private var arrow: String {
        price.isUp ? "▲" : (price.isDown ? "▼" : "–")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(price.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text(String(format: "$%.2f", price.price))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .monospacedDigit()

            Text(OilSymbol(rawValue: price.symbol)?.unit ?? "USD / barrel")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 3) {
                Text(arrow)
                Text(String(format: "%.2f", abs(price.change)))
                Text(String(format: "(%.2f%%)", abs(price.changePercent)))
            }
            .font(.caption)
            .foregroundStyle(changeColor)
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
}

struct EmptyPriceCardView: View {
    let name: String
    var unit: String = "USD / barrel"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("--")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text("-- (--%)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
}
