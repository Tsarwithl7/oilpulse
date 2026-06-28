<div align="center">

# 🛢️ OilPulse

**A lightweight, real-time crude oil price monitor for macOS.**

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Language](https://img.shields.io/badge/language-Swift-orange)
![UI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20Swift%20Charts-green)
![Status](https://img.shields.io/badge/status-MVP-yellow)

**English** | [简体中文](README.zh-CN.md)

</div>

---

## 📖 Overview

**OilPulse** is a lightweight tool that keeps an eye on crude oil prices in real time and surfaces them through a small, native macOS app. It runs locally and quietly — no browser, no heavy background services — so the latest **Brent** and **WTI** prices and recent trends are always one click away.

## 🎯 Why it matters

The goal is simple: **help you notice oil price movements the moment they happen.**

This is especially useful in the **United States**, where retail gas-station prices tend to follow crude oil with a short delay. When crude spikes, OilPulse lets you catch it early — so you can **fill up your tank *before* the pump prices catch up.** A few minutes of awareness can mean real savings at the gas station.

## ✨ Features

- 💵 Latest **Brent** & **WTI** prices, side by side
- 📈 Absolute change and percentage change (green ↑ / red ↓)
- 🕒 Trend charts for **1 Day / 1 Week / 1 Month**
- 🔄 Auto-refresh on open + scheduled refresh (15 / 30 / 60 min)
- ⚡ Manual refresh and **force refresh** (bypasses cooldown)
- 💾 Local **SQLite** cache — shows the last good data when offline
- 🚦 Clear status indicators: normal / cached / offline / failed
- 🚀 Optional launch at login

## 🛠️ Tech Stack

| Area | Technology |
|------|------------|
| Language | Swift |
| UI | SwiftUI + Swift Charts |
| Networking | URLSession (Yahoo Finance) |
| Local cache | SQLite |
| Preferences | UserDefaults / AppStorage |
| Launch at login | macOS Service Management |
| Build | Swift Package Manager |

## 📦 Build & Run

Requirements: **macOS 14+** and the **Swift toolchain** (Xcode or Command Line Tools).

```bash
# Clone
git clone https://github.com/Tsarwithl7/oilpulse.git
cd oil_monitor

# Build a release .app bundle
bash build.sh

# Launch
open OilMonitor.app
```

The app opens as a small window with both price cards and a trend chart. If macOS blocks the unsigned app on first launch, run:

```bash
xattr -cr OilMonitor.app && open OilMonitor.app
```

## 📄 Documentation

- [Product Requirements](product-requirements.md)

## ⚠️ Disclaimer

Data shown is for personal reference only and may be delayed or inaccurate. It does **not** constitute investment or trading advice.
