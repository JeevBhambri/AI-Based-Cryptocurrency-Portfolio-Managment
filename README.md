# Apex — Autonomous Crypto Portfolio Agent

> A multi-agent autonomous crypto portfolio analyst built on Claude. Six specialised agents (Data, Analysis, Risk, Strategy, Simulation, Explanation) collaborate to evaluate any crypto portfolio, surface concentration & volatility risks, generate a concrete rebalancing plan, and back-test that plan against the past 30 days of market data.

![stack](https://img.shields.io/badge/stack-Node%20%2B%20Express%20%2B%20React%20%2B%20Vite-7c5cff) ![ai](https://img.shields.io/badge/AI-Anthropic%20Claude%20Sonnet-06d6a0) ![data](https://img.shields.io/badge/data-CoinGecko%20%2B%20Etherscan-4dabff)

---

## Why this project stands out

Most "AI portfolio" projects are LLM wrappers around a single prompt. Apex is structured as a **true agent system** — each agent owns one responsibility, hands its output to the next, and emits live reasoning to the UI as it works.

What you'll see in the demo:

1. **Real-time agent reasoning panel** — every agent's thinking streams to the frontend via Server-Sent Events.
2. **Risk Agent + Strategy Agent + Explanation Agent** are real Claude calls with structured JSON output and graceful fallbacks.
3. **What-If simulation engine** — backtest the recommended strategy against actual prices to prove the agent's advice would have lowered drawdown and volatility.
4. **Three input modes** — manual entry, ETH wallet address (Etherscan), and CSV upload.
5. **Demo mode** — runs end-to-end with no API keys, so the project is screenshot-ready out of the box.

---

## Architecture

```
┌────────────────┐
│  React Client  │  Vite + Recharts · live SSE agent log · simulation chart
└────────┬───────┘
         │  fetch /api/portfolio/analyze (SSE)
         ▼
┌────────────────────┐
│  Express Server    │
│   /api/portfolio/  │
└────────┬───────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                                  │
│                                                                      │
│  Input Agent  →  Data Agent  →  Analysis Agent  →  Risk Agent       │
│                                                       │              │
│                                                       ▼              │
│                          Explanation Agent  ←  Strategy Agent       │
└─────────────────────────────────────────────────────────────────────┘
         │                           │
         ▼                           ▼
   CoinGecko API              Anthropic Claude
   Etherscan API              (Sonnet 4.6)
```

### Agents

| Agent | Type | Job |
| --- | --- | --- |
| **Input Agent** | deterministic | Parse manual / CSV / wallet input into normalised `{symbol, quantity}` |
| **Data Agent** | deterministic | Pull live prices + 24h moves from CoinGecko, compute USD value |
| **Analysis Agent** | deterministic | Compute allocation %, top movers, HHI diversification index, stables/majors/alts breakdown |
| **Risk Agent** | **Claude** | Evaluate concentration / volatility / correlation risks → structured JSON |
| **Strategy Agent** | **Claude** | Generate concrete rebalancing plan (3-5 moves with current → target %) |
| **Explanation Agent** | **Claude** | Rewrite findings as plain-English briefing for a non-technical user |
| **Simulation Engine** | deterministic | Backtest strategy vs. actual using 30d historical CoinGecko prices |

---

## Quickstart

### Prerequisites
- Node.js 18+
- (optional) Anthropic API key — get one at https://console.anthropic.com/settings/keys

### Run it

```bash
# 1. Install everything (root, server, client)
npm run install:all

# 2. Configure your keys
cp server/.env.example server/.env
# Edit server/.env and set ANTHROPIC_API_KEY=sk-ant-...
# OR keep DEMO_MODE=true to run with cached responses

# 3. Boot both servers concurrently
npm run dev
```

Or just run the launcher:

```bash
./start.sh        # macOS / Linux
start.bat         # Windows
```

Then open **http://localhost:5173**.

### Optional connectors
| Variable | What it unlocks |
| --- | --- |
| `ANTHROPIC_API_KEY` | Real LLM-driven Risk/Strategy/Explanation agents. Without this, set `DEMO_MODE=true`. |
| `ETHERSCAN_API_KEY` | Wallet-address input mode. Without it, the wallet tab returns a demo wallet so the UX still works. |

---

## Demo flow (for your Loom)

1. **Open http://localhost:5173** — the landing page shows the agent system explanation and an input panel.
2. **Manual entry tab**: Click "Run Multi-Agent Analysis" with the pre-filled BTC/ETH/SOL/USDC sample.
3. **Watch the right-side agent log stream** — each agent reports as it runs.
4. **Dashboard appears**: KPI cards (portfolio value, 24h change, diversification, largest position) + allocation pie + bar table.
5. **Read the plain-English Explanation card** — this is what a non-technical investor would actually read.
6. **Read the Risk + Strategy cards** on the right.
7. **Click "Backtest strategy"** in the simulation panel — Recharts shows actual vs. strategy portfolio over 30 days. The strategy line will typically show lower drawdown and lower volatility.
8. **Switch to Wallet tab** and paste any ETH address (e.g. `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045`).
9. **Switch to CSV tab** and drop `sample_portfolio.csv` from the project root.

---

## Endpoints

```
GET  /api/health                Server status, demo mode, key presence
POST /api/portfolio/analyze     Multi-agent analysis (SSE stream)
                                  Body: { mode: "manual", holdings: [...] }
                                     |  { mode: "wallet", address: "0x..." }
                                     |  multipart file + mode=csv
POST /api/portfolio/simulate    Backtest strategy vs actual
                                  Body: { holdings, strategy, days }
```

---

## Project structure

```
crypto-agent/
├── server/
│   ├── index.js                  Express + SSE bootstrap
│   ├── routes/portfolio.js       /analyze + /simulate routes
│   ├── agents/
│   │   ├── orchestrator.js       Runs the chain, streams trace
│   │   ├── dataAgent.js          Live price enrichment
│   │   ├── analysisAgent.js      HHI, breakdown, movers
│   │   ├── riskAgent.js          Claude — risk JSON
│   │   ├── strategyAgent.js      Claude — rebalancing JSON
│   │   ├── explanationAgent.js   Claude — plain-English JSON
│   │   └── simulationAgent.js    Backtest engine
│   ├── tools/
│   │   ├── claudeClient.js       Anthropic SDK wrapper, JSON extractor
│   │   ├── coingecko.js          Prices + history (with offline fallback)
│   │   ├── etherscan.js          Wallet → holdings (with demo fallback)
│   │   └── portfolioParser.js    CSV / manual parsers
│   └── data/demoResponses.js     Personalised offline responses
├── client/
│   └── src/
│       ├── App.jsx
│       ├── components/
│       │   ├── InputPanel.jsx    Tabs: manual / wallet / csv
│       │   ├── AgentLogs.jsx     Live SSE trace panel
│       │   ├── Dashboard.jsx     KPI grid + allocation pie + bar table
│       │   ├── RiskCard.jsx      Risk meter + key risks list
│       │   ├── StrategyCard.jsx  Move cards + exit strategy + next steps
│       │   ├── Explanation.jsx   Plain-English briefing
│       │   └── SimulationPanel.jsx  Backtest controls + dual-line chart
│       └── utils/api.js          SSE client + REST helpers
├── sample_portfolio.csv
├── start.sh / start.bat
└── README.md
```

---

## How the multi-agent reasoning is real (not theatre)

When Claude is configured (DEMO_MODE=false + valid key), each LLM-backed agent makes a discrete API call with:
- A **focused system prompt** describing its single responsibility (see `server/agents/*Agent.js`).
- **Only the data it needs** as the user message — the Strategy Agent does *not* see raw prices, only the Analysis Agent's summary + the Risk Agent's findings.
- A **strict JSON output contract** parsed in `tools/claudeClient.js`. If parsing fails, we degrade to the personalised fallback in `data/demoResponses.js` so the UX never breaks.

This is what makes the project look like a real fintech system rather than a single-prompt wrapper.

---

## License & disclaimer

Built for educational and demonstration purposes. Not financial advice. Use at your own risk.
