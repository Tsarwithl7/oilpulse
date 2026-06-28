# OilPulse MCP Server

把 OilPulse 的油价能力暴露成一个 [MCP](https://modelcontextprotocol.io) server，让 AI agent（Claude Desktop、Cursor 等）可以直接查询 **Brent / WTI 原油**的最新价格和近期走势。

数据来源为公开的 Yahoo Finance 行情接口（延迟行情，仅供信息参考，不构成投资建议）。

## 提供的工具

| 工具 | 说明 | 参数 |
| --- | --- | --- |
| `get_oil_price` | 查询当前油价（价格、涨跌额、涨跌幅、计价货币、行情时间） | `symbol`: `brent` / `wti` / `both`（默认 `both`） |
| `get_oil_history` | 查询历史走势（一组 `{time, price}` 点，含最高/最低价） | `symbol`: `brent` / `wti`；`range`: `1D` / `1W` / `1M`（默认 `1D`） |

返回示例（`get_oil_price`）：

```json
{
  "brent": {
    "symbol": "BZ=F", "name": "Brent", "price": 82.45, "currency": "USD",
    "unit": "barrel", "change": 0.53, "change_percent": 0.65,
    "direction": "up", "market_time": "2026-06-27T20:00:00+00:00",
    "source": "Yahoo Finance"
  },
  "wti": { "...": "..." }
}
```

## 安装

需要 Python 3.10+。推荐用 [uv](https://docs.astral.sh/uv/)，也可以用 pip。

```bash
cd mcp-server

# 方式 A：uv（推荐）
uv venv
uv pip install -r requirements.txt

# 方式 B：pip
python -m venv .venv
# Windows PowerShell:  .venv\Scripts\Activate.ps1
# macOS/Linux:         source .venv/bin/activate
pip install -r requirements.txt
```

## 本地调试

用官方 Inspector 直接连：

```bash
npx @modelcontextprotocol/inspector uv run server.py
```

或直接运行（stdio 模式，等待 MCP 客户端连接）：

```bash
uv run server.py
```

## 在 MCP 客户端中配置

### Cursor

编辑 `~/.cursor/mcp.json`（或项目内 `.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "oilpulse": {
      "command": "uv",
      "args": ["run", "--directory", "/绝对路径/oilpulse/mcp-server", "server.py"]
    }
  }
}
```

### Claude Desktop

编辑 `claude_desktop_config.json`：

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "oilpulse": {
      "command": "uv",
      "args": ["run", "--directory", "/绝对路径/oilpulse/mcp-server", "server.py"]
    }
  }
}
```

> 不用 uv 时，把 `command` 换成虚拟环境里的 `python`，`args` 换成 `["/绝对路径/oilpulse/mcp-server/server.py"]` 即可。

配置好后重启客户端，就可以让 AI 直接问“现在 Brent 原油多少钱？”、“给我看 WTI 最近一周的走势”。

## 说明

- 行情为延迟数据，仅供个人信息参考，不构成投资或交易建议。
- 该 server 独立运行，无需先编译或启动 macOS 端的 OilPulse 应用。
