"""OilPulse MCP server.

Exposes Brent / WTI crude oil prices and recent price trends to AI agents
over the Model Context Protocol. Data comes from the public Yahoo Finance
chart API (delayed quotes, for informational use only).
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Literal

import httpx
from mcp.server.fastmcp import FastMCP

# Yahoo Finance ticker symbols for the supported instruments.
SYMBOLS: dict[str, dict[str, str]] = {
    "brent": {"ticker": "BZ=F", "name": "Brent"},
    "wti": {"ticker": "CL=F", "name": "WTI"},
}

# Maps a friendly time range to Yahoo's (interval, range) query parameters.
RANGES: dict[str, dict[str, str]] = {
    "1D": {"interval": "5m", "range": "1d"},
    "1W": {"interval": "30m", "range": "5d"},
    "1M": {"interval": "1d", "range": "1mo"},
}

BASE_URL = "https://query2.finance.yahoo.com/v8/finance/chart/"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15",
    "Accept": "application/json",
}
TIMEOUT = httpx.Timeout(20.0)

mcp = FastMCP("oilpulse")


def _resolve_symbol(symbol: str) -> tuple[str, str]:
    """Return (ticker, display_name) for a friendly symbol key."""
    key = symbol.strip().lower()
    if key not in SYMBOLS:
        raise ValueError(
            f"Unknown symbol '{symbol}'. Use one of: {', '.join(SYMBOLS)}."
        )
    info = SYMBOLS[key]
    return info["ticker"], info["name"]


async def _fetch_chart(ticker: str, interval: str, rng: str) -> dict[str, Any]:
    params = {"interval": interval, "range": rng}
    async with httpx.AsyncClient(timeout=TIMEOUT, headers=HEADERS) as client:
        resp = await client.get(BASE_URL + ticker, params=params)
        resp.raise_for_status()
        return resp.json()


def _iso(ts: int | float) -> str:
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()


@mcp.tool()
async def get_oil_price(
    symbol: Literal["brent", "wti", "both"] = "both",
) -> dict[str, Any]:
    """Get the latest crude oil price.

    Returns the current price, absolute change, percent change, currency and
    the market time of the last trade for Brent and/or WTI.

    Args:
        symbol: "brent", "wti", or "both" (default) to fetch both instruments.
    """
    keys = list(SYMBOLS) if symbol == "both" else [symbol.lower()]
    results: dict[str, Any] = {}

    for key in keys:
        ticker, name = _resolve_symbol(key)
        try:
            data = await _fetch_chart(ticker, "1d", "2d")
            result = data["chart"]["result"][0]
            meta = result["meta"]
            price = meta["regularMarketPrice"]
            prev_close = (
                meta.get("previousClose")
                or meta.get("chartPreviousClose")
                or price
            )
            change = price - prev_close
            change_percent = (change / prev_close * 100) if prev_close else 0.0
            market_time = meta.get(
                "regularMarketTime", int(datetime.now(tz=timezone.utc).timestamp())
            )
            results[key] = {
                "symbol": ticker,
                "name": name,
                "price": round(price, 2),
                "currency": meta.get("currency", "USD"),
                "unit": "barrel",
                "change": round(change, 2),
                "change_percent": round(change_percent, 2),
                "direction": "up" if change > 0 else "down" if change < 0 else "flat",
                "market_time": _iso(market_time),
                "source": "Yahoo Finance",
            }
        except (httpx.HTTPError, KeyError, IndexError, TypeError) as exc:
            results[key] = {"error": f"Failed to fetch {name}: {exc}"}

    if symbol != "both":
        return results[symbol.lower()]
    return results


@mcp.tool()
async def get_oil_history(
    symbol: Literal["brent", "wti"],
    range: Literal["1D", "1W", "1M"] = "1D",
) -> dict[str, Any]:
    """Get recent price history (trend) for a crude oil instrument.

    Returns a list of {time, price} points suitable for plotting a trend line.

    Args:
        symbol: "brent" or "wti".
        range: time window — "1D" (intraday 5m), "1W" (30m), or "1M" (daily).
    """
    ticker, name = _resolve_symbol(symbol)
    cfg = RANGES[range]

    try:
        data = await _fetch_chart(ticker, cfg["interval"], cfg["range"])
        result = data["chart"]["result"][0]
        timestamps: list[int] = result.get("timestamp", []) or []
        closes = (
            result.get("indicators", {}).get("quote", [{}])[0].get("close", []) or []
        )
    except (httpx.HTTPError, KeyError, IndexError, TypeError) as exc:
        return {"error": f"Failed to fetch history for {name}: {exc}"}

    points: list[dict[str, Any]] = []
    for ts, close in zip(timestamps, closes):
        if close is None or close <= 0:
            continue
        points.append({"time": _iso(ts), "price": round(close, 2)})

    prices = [p["price"] for p in points]
    return {
        "symbol": ticker,
        "name": name,
        "range": range,
        "currency": "USD",
        "unit": "barrel",
        "count": len(points),
        "high": max(prices) if prices else None,
        "low": min(prices) if prices else None,
        "points": points,
        "source": "Yahoo Finance",
    }


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
