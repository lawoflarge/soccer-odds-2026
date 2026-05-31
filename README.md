# World Cup 2026 Odds

Market-consensus match predictions for the 2026 World Cup — a free iOS app backed by a zero-cost data pipeline.

For each match the app shows what the betting market expects: win/draw/win probabilities, the most likely scorelines, and goal markets (Over/Under 2.5, both teams to score) — derived from aggregated bookmaker odds. Built to help people make smarter predictions in their friends' prediction pools, and to follow how their favorite team is likely to perform.

> **Unofficial.** Not affiliated with, endorsed by, or connected to FIFA. For entertainment and information only — no betting, no real-money gaming.

## How it works

```
GitHub Actions (every 6h)
  → fetch bookmaker odds (The Odds API, region eu, markets h2h + totals)
  → devig to a fair consensus, calibrate a Poisson/Dixon-Coles goal model
  → write web/public/predictions.json
Vercel (static)  → serves predictions.json over CDN
iOS app (SwiftUI) → loads + caches the JSON, renders predictions, AdMob
```

All odds-fetching and probability math happens **once, centrally** in the scheduled job — never on the device. Running cost is **0 €** regardless of downloads (strict free-tier budget: ~240 of 500 monthly API credits).

## Repository layout

```
pipeline/   Node (ESM) data pipeline — devig, Poisson/Dixon-Coles, JSON build (unit-tested)
web/        Static Vercel host for predictions.json
ios/        SwiftUI app (see docs/superpowers/plans/*-ios-app.md)
docs/       Design spec + implementation plans
.github/    Actions cron that refreshes predictions every 6h
```

## `predictions.json` schema

```jsonc
{
  "updated": "2026-06-01T00:00:00Z",   // ISO 8601 UTC
  "count": 104,
  "matches": [
    {
      "id": "evt_...",
      "teams": { "home": "Mexico", "away": "Poland" },
      "kickoff": "2026-06-11T19:00:00Z",
      "probs_1x2": { "home": 48.3, "draw": 27.4, "away": 24.3 },
      "top_scores": [ { "score": "1:1", "pct": 13.1 } ],
      "goal_markets": { "over_under_2_5": 47.4, "btts": 51.4 }
    }
  ]
}
```

## Pipeline — develop

```bash
cd pipeline
node --test                       # run the unit suite (no deps, Node 18+)
ODDS_API_KEY=<key> npm run build  # live build -> web/public/predictions.json
```

Get a free key at <https://the-odds-api.com/>.

## Status

- ✅ Data pipeline core — implemented, unit-tested, reviewed
- ✅ Live feed — served at <https://world-cup-2026-odds.vercel.app/predictions.json> (CORS-enabled), refreshed every 6h by GitHub Actions
- ⏳ iOS app — planned (`docs/superpowers/plans/`)

## License

Private project. All rights reserved.
