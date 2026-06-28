<div align="center">

# 🛢️ OilPulse

**一款轻量化、可本地运行的 macOS 实时油价监控工具。**

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Language](https://img.shields.io/badge/language-Swift-orange)
![UI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20Swift%20Charts-green)
![Status](https://img.shields.io/badge/status-MVP-yellow)

[English](README.md) | **简体中文**

</div>

---

## 📖 项目简介

**OilPulse** 是一个轻量化的实时油价监控工具，通过一个原生的 macOS 小应用展示数据。它**完全在本地运行、安静轻便**——无需浏览器、无需常驻重型后台服务——让你随时一键查看 **Brent（布伦特）** 与 **WTI（西德州中质原油）** 的最新价格和近期走势。

## 🎯 主要目的

目标很直接：**让你在油价发生变动的第一时间察觉到。**

这在**美国**尤其实用——加油站的零售价通常会**滞后**于国际原油价格几天才调整。当原油大涨时，OilPulse 能让你提前发现，从而**赶在加油站涨价之前先把油加满**。提前几分钟的信息差，往往就能在加油时省下实实在在的钱。

## ✨ 功能特性

- 💵 **Brent** 与 **WTI** 最新价格并排展示
- 📈 涨跌额与涨跌幅（绿涨 ↑ / 红跌 ↓）
- 🕒 **1 天 / 1 周 / 1 月** 趋势图
- 🔄 打开即自动刷新 + 定时刷新（15 / 30 / 60 分钟）
- ⚡ 普通手动更新与**强制更新**（忽略冷却）
- 💾 本地 **SQLite** 缓存——离线时展示最近一次有效数据
- 🚦 清晰的状态指示：正常 / 缓存 / 离线 / 失败
- 🚀 可选开机自动启动

## 🛠️ 技术栈

| 模块 | 技术 |
|------|------|
| 开发语言 | Swift |
| 界面 | SwiftUI + Swift Charts |
| 网络请求 | URLSession（Yahoo Finance） |
| 本地缓存 | SQLite |
| 偏好设置 | UserDefaults / AppStorage |
| 开机启动 | macOS Service Management |
| 构建 | Swift Package Manager |

## 📦 构建与运行

环境要求：**macOS 14 及以上**，以及 **Swift 工具链**（Xcode 或命令行工具）。

```bash
# 克隆仓库
git clone https://github.com/Tsarwithl7/oilpulse.git
cd oil_monitor

# 构建 release 版 .app
bash build.sh

# 启动
open OilMonitor.app
```

应用会以一个小窗口打开，显示价格卡片和趋势图。如果首次启动时 macOS 因为应用未签名而拦截，运行：

```bash
xattr -cr OilMonitor.app && open OilMonitor.app
```

## 📄 项目文档

- [产品需求文档](product-requirements.md)

## ⚠️ 免责声明

本项目展示的数据仅供个人信息参考，可能存在延迟或误差，**不构成**任何投资或交易建议。
