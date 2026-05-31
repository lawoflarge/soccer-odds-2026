# Data Pipeline + Hosting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a zero-cost Node pipeline that fetches World Cup bookmaker odds, computes consensus probabilities (1X2, correct-score via Poisson/Dixon-Coles, O/U 2.5, BTTS), writes a static `predictions.json`, and serves it live on Vercel — refreshed every 6h by GitHub Actions.

**Architecture:** A small ESM Node project (`pipeline/`) with pure, unit-tested math modules (devig, Poisson) and an orchestrator that turns The Odds API response into `predictions.json`. A static `web/` directory hosts the JSON on Vercel Hobby. A GitHub Actions cron runs the pipeline and commits the refreshed JSON. No database, no server.

**Tech Stack:** Node 18+ (global `fetch`, ESM), Node's built-in test runner (`node --test`, zero deps), The Odds API, GitHub Actions, Vercel static hosting.

---

## File Structure

```
pipeline/
  package.json              # ESM, scripts: test, build
  src/
    devig.js                # implied probs, proportional devig, 1X2 & totals consensus
    poisson.js              # poisson pmf/tail, Dixon-Coles grid, market derivation, lambda solver
    transform.js            # one Odds API match -> prediction object
    buildPredictions.js     # fetch all + transform all + write web/public/predictions.json
    oddsApi.js              # fetch wrapper for The Odds API
  test/
    devig.test.js
    poisson.test.js
    transform.test.js
  fixtures/
    sample-odds.json        # one realistic Odds API match, for transform test
web/
  public/
    predictions.json        # generated output (committed)
  vercel.json               # CORS + cache headers for the JSON
.github/
  workflows/
    update-predictions.yml  # cron every 6h: run build, commit if changed
```

**Responsibilities:** `devig.js` and `poisson.js` are pure math (no I/O), fully unit-tested. `oddsApi.js` is the only network boundary. `transform.js` maps one match (pure, testable with a fixture). `buildPredictions.js` is the only file that touches the filesystem and orchestrates everything.

---

## Task 1: Project scaffold

**Files:**
- Create: `pipeline/package.json`

- [ ] **Step 1: Create `pipeline/package.json`**

```json
{
  "name": "worldcupp-2026-odds-pipeline",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "engines": { "node": ">=18" },
  "scripts": {
    "test": "node --test",
    "build": "node src/buildPredictions.js"
  }
}
```

- [ ] **Step 2: Verify the test runner works (no tests yet)**

Run: `cd pipeline && node --test`
Expected: exits 0 with "tests 0" (no test files found yet is fine).

- [ ] **Step 3: Commit**

```bash
git add pipeline/package.json
git commit -m "chore: scaffold pipeline project"
```

---

## Task 2: Devig — implied probabilities & proportional margin removal

**Files:**
- Create: `pipeline/src/devig.js`
- Test: `pipeline/test/devig.test.js`

- [ ] **Step 1: Write the failing test**

```javascript
// pipeline/test/devig.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { devigProportional } from "../src/devig.js";

const close = (a, b, eps = 1e-4) => Math.abs(a - b) <= eps;

test("devigProportional removes the bookmaker margin and sums to 1", () => {
  const fair = devigProportional([2.1, 3.4, 3.6]); // home/draw/away
  assert.ok(close(fair[0] + fair[1] + fair[2], 1), "probs must sum to 1");
  assert.ok(close(fair[0], 0.45435), `home was ${fair[0]}`);
  assert.ok(close(fair[1], 0.28063), `draw was ${fair[1]}`);
  assert.ok(close(fair[2], 0.26502), `away was ${fair[2]}`);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd pipeline && node --test test/devig.test.js`
Expected: FAIL — "Cannot find module '../src/devig.js'".

- [ ] **Step 3: Write minimal implementation**

```javascript
// pipeline/src/devig.js

// Convert decimal odds to implied probabilities (still contains margin).
export function impliedProbs(decimalOdds) {
  return decimalOdds.map((o) => 1 / o);
}

// Remove the bookmaker margin by proportional normalization.
export function devigProportional(decimalOdds) {
  const imp = impliedProbs(decimalOdds);
  const overround = imp.reduce((a, b) => a + b, 0);
  return imp.map((p) => p / overround);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd pipeline && node --test test/devig.test.js`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add pipeline/src/devig.js pipeline/test/devig.test.js
git commit -m "feat: proportional devig of decimal odds"
```

---

## Task 3: Consensus across bookmakers (1X2 and totals)

**Files:**
- Modify: `pipeline/src/devig.js`
- Modify: `pipeline/test/devig.test.js`

- [ ] **Step 1: Add the failing tests**

Append to `pipeline/test/devig.test.js`:

```javascript
import { consensus1x2, consensusOver } from "../src/devig.js";

test("consensus1x2 averages devigged probabilities across books", () => {
  const books = [
    [2.1, 3.4, 3.6],
    [2.05, 3.5, 3.7],
  ];
  const c = consensus1x2(books);
  assert.ok(close(c.home + c.draw + c.away, 1), "consensus must sum to 1");
  assert.ok(c.home > c.away, "home favourite should have higher prob");
});

test("consensusOver averages devigged over-2.5 probability across books", () => {
  // each book: [overOdds, underOdds]
  const books = [
    [1.9, 1.9],
    [2.0, 1.8],
  ];
  const over = consensusOver(books);
  assert.ok(over > 0 && over < 1, `over was ${over}`);
  assert.ok(close(over, 0.4862, 1e-3), `over was ${over}`);
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd pipeline && node --test test/devig.test.js`
Expected: FAIL — `consensus1x2`/`consensusOver` not exported.

- [ ] **Step 3: Implement**

Append to `pipeline/src/devig.js`:

```javascript
// books: array of [homeOdds, drawOdds, awayOdds]
export function consensus1x2(books) {
  const fair = books.map((b) => devigProportional(b));
  const n = fair.length;
  const sum = fair.reduce(
    (acc, f) => [acc[0] + f[0], acc[1] + f[1], acc[2] + f[2]],
    [0, 0, 0],
  );
  return { home: sum[0] / n, draw: sum[1] / n, away: sum[2] / n };
}

// books: array of [overOdds, underOdds] -> average fair "over" probability
export function consensusOver(books) {
  const fairOver = books.map((b) => devigProportional(b)[0]);
  return fairOver.reduce((a, b) => a + b, 0) / fairOver.length;
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd pipeline && node --test test/devig.test.js`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add pipeline/src/devig.js pipeline/test/devig.test.js
git commit -m "feat: multi-bookmaker consensus for 1X2 and totals"
```

---

## Task 4: Poisson primitives

**Files:**
- Create: `pipeline/src/poisson.js`
- Test: `pipeline/test/poisson.test.js`

- [ ] **Step 1: Write the failing test**

```javascript
// pipeline/test/poisson.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { poissonPmf, poissonTail } from "../src/poisson.js";

const close = (a, b, eps = 1e-4) => Math.abs(a - b) <= eps;

test("poissonPmf matches known values for lambda=1.5", () => {
  assert.ok(close(poissonPmf(0, 1.5), 0.22313), `${poissonPmf(0, 1.5)}`);
  assert.ok(close(poissonPmf(2, 1.5), 0.25102), `${poissonPmf(2, 1.5)}`);
});

test("poissonTail gives P(N>=threshold)", () => {
  // P(N>=3) for lambda=2.5
  assert.ok(close(poissonTail(2.5, 3), 0.45619), `${poissonTail(2.5, 3)}`);
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement**

```javascript
// pipeline/src/poisson.js

export function factorial(n) {
  let r = 1;
  for (let i = 2; i <= n; i++) r *= i;
  return r;
}

export function poissonPmf(k, lambda) {
  return (Math.exp(-lambda) * lambda ** k) / factorial(k);
}

// P(N >= threshold) for N ~ Poisson(lambda)
export function poissonTail(lambda, threshold) {
  let cdf = 0;
  for (let k = 0; k < threshold; k++) cdf += poissonPmf(k, lambda);
  return 1 - cdf;
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add pipeline/src/poisson.js pipeline/test/poisson.test.js
git commit -m "feat: poisson pmf and tail"
```

---

## Task 5: Dixon-Coles score grid + market derivation

**Files:**
- Modify: `pipeline/src/poisson.js`
- Modify: `pipeline/test/poisson.test.js`

- [ ] **Step 1: Add failing tests**

Append to `pipeline/test/poisson.test.js`:

```javascript
import { scoreGrid, marketsFromGrid } from "../src/poisson.js";

test("scoreGrid is a normalized probability distribution", () => {
  const grid = scoreGrid(1.6, 1.1);
  let total = 0;
  for (const row of grid) for (const p of row) total += p;
  assert.ok(close(total, 1), `grid total was ${total}`);
});

test("marketsFromGrid: stronger home rate => higher home win prob", () => {
  const m = marketsFromGrid(scoreGrid(1.9, 0.9));
  assert.ok(close(m.home + m.draw + m.away, 1), "1X2 must sum to 1");
  assert.ok(m.home > m.away, "home should be favoured");
  assert.ok(m.over > 0 && m.over < 1, `over was ${m.over}`);
  assert.ok(m.btts > 0 && m.btts < 1, `btts was ${m.btts}`);
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: FAIL — `scoreGrid`/`marketsFromGrid` not exported.

- [ ] **Step 3: Implement**

Append to `pipeline/src/poisson.js`:

```javascript
// Dixon-Coles low-score dependency adjustment.
// lambdaHome=home rate, lambdaAway=away rate, rho≈-0.08.
export function dixonColesTau(x, y, lambdaHome, lambdaAway, rho) {
  if (x === 0 && y === 0) return 1 - lambdaHome * lambdaAway * rho;
  if (x === 0 && y === 1) return 1 + lambdaHome * rho;
  if (x === 1 && y === 0) return 1 + lambdaAway * rho;
  if (x === 1 && y === 1) return 1 - rho;
  return 1;
}

// Returns grid[x][y] = P(home=x, away=y), normalized. maxGoals inclusive.
export function scoreGrid(lambdaHome, lambdaAway, rho = -0.08, maxGoals = 8) {
  const grid = [];
  let total = 0;
  for (let x = 0; x <= maxGoals; x++) {
    grid[x] = [];
    for (let y = 0; y <= maxGoals; y++) {
      const p =
        poissonPmf(x, lambdaHome) *
        poissonPmf(y, lambdaAway) *
        dixonColesTau(x, y, lambdaHome, lambdaAway, rho);
      grid[x][y] = p;
      total += p;
    }
  }
  for (let x = 0; x <= maxGoals; x++)
    for (let y = 0; y <= maxGoals; y++) grid[x][y] /= total;
  return grid;
}

// Derive 1X2 / over-2.5 / BTTS probabilities from a score grid.
export function marketsFromGrid(grid) {
  let home = 0,
    draw = 0,
    away = 0,
    over = 0,
    btts = 0;
  const maxGoals = grid.length - 1;
  for (let x = 0; x <= maxGoals; x++)
    for (let y = 0; y <= maxGoals; y++) {
      const p = grid[x][y];
      if (x > y) home += p;
      else if (x === y) draw += p;
      else away += p;
      if (x + y >= 3) over += p;
      if (x >= 1 && y >= 1) btts += p;
    }
  return { home, draw, away, over, btts };
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: PASS (all 4 tests).

- [ ] **Step 5: Commit**

```bash
git add pipeline/src/poisson.js pipeline/test/poisson.test.js
git commit -m "feat: dixon-coles score grid and market derivation"
```

---

## Task 6: Calibrate lambdas from market 1X2 + Over 2.5

**Files:**
- Modify: `pipeline/src/poisson.js`
- Modify: `pipeline/test/poisson.test.js`

- [ ] **Step 1: Add failing test**

Append to `pipeline/test/poisson.test.js`:

```javascript
import { solveLambdas } from "../src/poisson.js";

test("solveLambdas reproduces the target market within tolerance", () => {
  const target1x2 = { home: 0.55, draw: 0.26, away: 0.19 };
  const targetOver = 0.52;
  const { lambdaHome, lambdaAway } = solveLambdas(target1x2, targetOver);
  const m = marketsFromGrid(scoreGrid(lambdaHome, lambdaAway));
  assert.ok(close(m.home, target1x2.home, 0.02), `home ${m.home}`);
  assert.ok(close(m.over, targetOver, 0.03), `over ${m.over}`);
  assert.ok(lambdaHome > lambdaAway, "home rate should exceed away rate");
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: FAIL — `solveLambdas` not exported.

- [ ] **Step 3: Implement**

Append to `pipeline/src/poisson.js`:

```javascript
// Find total goal expectation mu so that P(total>=3) == targetOver,
// total ~ Poisson(mu). Bisection.
export function solveMu(targetOver, threshold = 3) {
  let lo = 0.2,
    hi = 8;
  for (let i = 0; i < 60; i++) {
    const mid = (lo + hi) / 2;
    if (poissonTail(mid, threshold) < targetOver) lo = mid;
    else hi = mid;
  }
  return (lo + hi) / 2;
}

// Given consensus 1X2 + over-2.5, back out home/away scoring rates.
// Step 1: mu = lambdaHome+lambdaAway from the totals market.
// Step 2: bisection on supremacy s=lambdaHome-lambdaAway to match home-win prob.
export function solveLambdas(target1x2, targetOver, rho = -0.08) {
  const mu = solveMu(targetOver);
  let lo = -mu + 0.05,
    hi = mu - 0.05;
  for (let i = 0; i < 60; i++) {
    const s = (lo + hi) / 2;
    const lh = (mu + s) / 2;
    const la = (mu - s) / 2;
    const m = marketsFromGrid(scoreGrid(lh, la, rho));
    if (m.home < target1x2.home) lo = s;
    else hi = s;
  }
  const s = (lo + hi) / 2;
  return { lambdaHome: (mu + s) / 2, lambdaAway: (mu - s) / 2 };
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: PASS (all 5 tests).

- [ ] **Step 5: Commit**

```bash
git add pipeline/src/poisson.js pipeline/test/poisson.test.js
git commit -m "feat: calibrate scoring rates from market 1X2 and totals"
```

---

## Task 7: Top scorelines helper

**Files:**
- Modify: `pipeline/src/poisson.js`
- Modify: `pipeline/test/poisson.test.js`

- [ ] **Step 1: Add failing test**

Append to `pipeline/test/poisson.test.js`:

```javascript
import { topScores } from "../src/poisson.js";

test("topScores returns N most likely scorelines, descending", () => {
  const top = topScores(scoreGrid(1.6, 1.1), 5);
  assert.equal(top.length, 5);
  for (let i = 1; i < top.length; i++)
    assert.ok(top[i - 1].pct >= top[i].pct, "must be sorted descending");
  assert.match(top[0].score, /^\d+:\d+$/, "score formatted as H:A");
});
```

- [ ] **Step 2: Run to verify failure**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: FAIL — `topScores` not exported.

- [ ] **Step 3: Implement**

Append to `pipeline/src/poisson.js`:

```javascript
// Flatten a grid into the N most likely scorelines.
// Returns [{ score: "2:1", pct: 9.1 }, ...] with pct rounded to 1 dp.
export function topScores(grid, n = 5) {
  const flat = [];
  for (let x = 0; x < grid.length; x++)
    for (let y = 0; y < grid[x].length; y++)
      flat.push({ score: `${x}:${y}`, p: grid[x][y] });
  flat.sort((a, b) => b.p - a.p);
  return flat.slice(0, n).map((s) => ({
    score: s.score,
    pct: Math.round(s.p * 1000) / 10,
  }));
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd pipeline && node --test test/poisson.test.js`
Expected: PASS (all 6 tests).

- [ ] **Step 5: Commit**

```bash
git add pipeline/src/poisson.js pipeline/test/poisson.test.js
git commit -m "feat: top scorelines from score grid"
```

---

## Task 8: Transform one Odds API match into a prediction object

**Files:**
- Create: `pipeline/src/transform.js`
- Create: `pipeline/fixtures/sample-odds.json`
- Test: `pipeline/test/transform.test.js`

The Odds API `/v4/sports/{sport}/odds` returns an array of events. Each event has `id`, `commence_time` (ISO 8601 UTC), `home_team`, `away_team`, and `bookmakers[]`. Each bookmaker has `markets[]`; a market has `key` (`"h2h"` or `"totals"`) and `outcomes[]`. For `h2h`, outcomes are `{name: <team or "Draw">, price}`. For `totals`, outcomes are `{name: "Over"|"Under", point, price}`.

- [ ] **Step 1: Create the fixture**

```json
// pipeline/fixtures/sample-odds.json
{
  "id": "evt_demo_001",
  "commence_time": "2026-06-11T19:00:00Z",
  "home_team": "Mexico",
  "away_team": "Poland",
  "bookmakers": [
    {
      "key": "book_a",
      "markets": [
        {
          "key": "h2h",
          "outcomes": [
            { "name": "Mexico", "price": 1.95 },
            { "name": "Draw", "price": 3.4 },
            { "name": "Poland", "price": 4.2 }
          ]
        },
        {
          "key": "totals",
          "outcomes": [
            { "name": "Over", "point": 2.5, "price": 2.05 },
            { "name": "Under", "point": 2.5, "price": 1.8 }
          ]
        }
      ]
    },
    {
      "key": "book_b",
      "markets": [
        {
          "key": "h2h",
          "outcomes": [
            { "name": "Mexico", "price": 2.0 },
            { "name": "Draw", "price": 3.3 },
            { "name": "Poland", "price": 4.0 }
          ]
        },
        {
          "key": "totals",
          "outcomes": [
            { "name": "Over", "point": 2.5, "price": 2.0 },
            { "name": "Under", "point": 2.5, "price": 1.85 }
          ]
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Write the failing test**

```javascript
// pipeline/test/transform.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { transformMatch } from "../src/transform.js";

const sample = JSON.parse(
  readFileSync(fileURLToPath(new URL("../fixtures/sample-odds.json", import.meta.url))),
);

test("transformMatch produces a complete prediction object", () => {
  const m = transformMatch(sample);
  assert.equal(m.id, "evt_demo_001");
  assert.equal(m.teams.home, "Mexico");
  assert.equal(m.teams.away, "Poland");
  assert.equal(m.kickoff, "2026-06-11T19:00:00Z");

  const { home, draw, away } = m.probs_1x2;
  assert.ok(Math.abs(home + draw + away - 100) < 0.5, "1X2 should sum to ~100");
  assert.ok(home > away, "Mexico favoured");

  assert.equal(m.top_scores.length, 5);
  assert.match(m.top_scores[0].score, /^\d+:\d+$/);

  assert.ok(m.goal_markets.over_under_2_5 >= 0 && m.goal_markets.over_under_2_5 <= 100);
  assert.ok(m.goal_markets.btts >= 0 && m.goal_markets.btts <= 100);
});

test("transformMatch returns null when h2h or totals data is missing", () => {
  const broken = { ...sample, bookmakers: [] };
  assert.equal(transformMatch(broken), null);
});
```

- [ ] **Step 3: Run to verify failure**

Run: `cd pipeline && node --test test/transform.test.js`
Expected: FAIL — module not found.

- [ ] **Step 4: Implement**

```javascript
// pipeline/src/transform.js
import { consensus1x2, consensusOver } from "./devig.js";
import { solveLambdas, scoreGrid, marketsFromGrid, topScores } from "./poisson.js";

const pct = (x) => Math.round(x * 1000) / 10;

// Collect [homeOdds, drawOdds, awayOdds] from every bookmaker's h2h market.
function h2hBooks(event) {
  const books = [];
  for (const b of event.bookmakers ?? []) {
    const mkt = b.markets?.find((m) => m.key === "h2h");
    if (!mkt) continue;
    const h = mkt.outcomes.find((o) => o.name === event.home_team)?.price;
    const a = mkt.outcomes.find((o) => o.name === event.away_team)?.price;
    const d = mkt.outcomes.find((o) => o.name === "Draw")?.price;
    if (h && d && a) books.push([h, d, a]);
  }
  return books;
}

// Collect [overOdds, underOdds] for the 2.5 line from every bookmaker.
function totalsBooks(event) {
  const books = [];
  for (const b of event.bookmakers ?? []) {
    const mkt = b.markets?.find((m) => m.key === "totals");
    if (!mkt) continue;
    const over = mkt.outcomes.find((o) => o.name === "Over" && o.point === 2.5)?.price;
    const under = mkt.outcomes.find((o) => o.name === "Under" && o.point === 2.5)?.price;
    if (over && under) books.push([over, under]);
  }
  return books;
}

// Map one Odds API event to a prediction object, or null if data is insufficient.
export function transformMatch(event) {
  const h2h = h2hBooks(event);
  const totals = totalsBooks(event);
  if (h2h.length === 0 || totals.length === 0) return null;

  const c = consensus1x2(h2h);
  const over = consensusOver(totals);

  const { lambdaHome, lambdaAway } = solveLambdas(c, over);
  const grid = scoreGrid(lambdaHome, lambdaAway);
  const m = marketsFromGrid(grid);

  return {
    id: event.id,
    teams: { home: event.home_team, away: event.away_team },
    kickoff: event.commence_time,
    probs_1x2: { home: pct(m.home), draw: pct(m.draw), away: pct(m.away) },
    top_scores: topScores(grid, 5),
    goal_markets: { over_under_2_5: pct(m.over), btts: pct(m.btts) },
  };
}
```

- [ ] **Step 5: Run to verify pass**

Run: `cd pipeline && node --test test/transform.test.js`
Expected: PASS (both tests).

- [ ] **Step 6: Run the whole suite**

Run: `cd pipeline && node --test`
Expected: PASS — all test files green.

- [ ] **Step 7: Commit**

```bash
git add pipeline/src/transform.js pipeline/fixtures/sample-odds.json pipeline/test/transform.test.js
git commit -m "feat: transform an odds event into a prediction object"
```

---

## Task 9: Odds API fetch wrapper

**Files:**
- Create: `pipeline/src/oddsApi.js`

No network test (keep tests offline & deterministic). This is a thin boundary verified manually in Task 10.

- [ ] **Step 1: Implement**

```javascript
// pipeline/src/oddsApi.js
const BASE = "https://api.the-odds-api.com/v4";
const SPORT = "soccer_fifa_world_cup";

// Fetch World Cup odds: region=eu, markets=h2h,totals (2 credits/call).
// Returns the parsed array of events.
export async function fetchWorldCupOdds(apiKey) {
  const url =
    `${BASE}/sports/${SPORT}/odds/` +
    `?apiKey=${apiKey}&regions=eu&markets=h2h,totals&oddsFormat=decimal`;
  const res = await fetch(url);
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Odds API ${res.status}: ${body}`);
  }
  const remaining = res.headers.get("x-requests-remaining");
  if (remaining !== null) console.error(`Odds API credits remaining: ${remaining}`);
  return res.json();
}
```

- [ ] **Step 2: Commit**

```bash
git add pipeline/src/oddsApi.js
git commit -m "feat: the odds api fetch wrapper"
```

---

## Task 10: Build orchestrator — write predictions.json

**Files:**
- Create: `pipeline/src/buildPredictions.js`
- Create (generated): `web/public/predictions.json`

- [ ] **Step 1: Implement the orchestrator**

```javascript
// pipeline/src/buildPredictions.js
import { writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { fetchWorldCupOdds } from "./oddsApi.js";
import { transformMatch } from "./transform.js";

const here = dirname(fileURLToPath(import.meta.url));
const OUT = resolve(here, "../../web/public/predictions.json");

async function main() {
  const apiKey = process.env.ODDS_API_KEY;
  if (!apiKey) {
    console.error("ODDS_API_KEY is not set");
    process.exit(1);
  }

  const events = await fetchWorldCupOdds(apiKey);
  const matches = events.map(transformMatch).filter(Boolean);
  // Stable ordering by kickoff so diffs are minimal between runs.
  matches.sort((a, b) => a.kickoff.localeCompare(b.kickoff));

  const payload = {
    updated: new Date().toISOString(),
    count: matches.length,
    matches,
  };

  mkdirSync(dirname(OUT), { recursive: true });
  writeFileSync(OUT, JSON.stringify(payload, null, 2) + "\n");
  console.error(`Wrote ${matches.length} matches to ${OUT}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 2: Smoke-test against the fixture (no live API, no key needed)**

Confirm the transform chain works end-to-end with the offline fixture:

Run:
```bash
cd pipeline && node --input-type=module -e '
import { transformMatch } from "./src/transform.js";
import { readFileSync } from "node:fs";
const s = JSON.parse(readFileSync("./fixtures/sample-odds.json"));
console.log(JSON.stringify(transformMatch(s), null, 2));
'
```
Expected: a fully populated prediction object printed (id `evt_demo_001`, Mexico favoured, 5 top scores).

- [ ] **Step 3: Live run (requires a free Odds API key)**

Get a free key at https://the-odds-api.com/ (signup → API key). Then:

Run: `cd pipeline && ODDS_API_KEY=<your_key> npm run build`
Expected: stderr prints "Odds API credits remaining: N" and "Wrote M matches to .../predictions.json". `web/public/predictions.json` now exists.

Note: before the tournament's odds are published, `M` may be small or 0 — that is expected. The pipeline is correct as long as it writes valid JSON. Re-run closer to kickoff for the full 104.

- [ ] **Step 4: Commit the orchestrator and the generated JSON**

```bash
git add pipeline/src/buildPredictions.js web/public/predictions.json
git commit -m "feat: build orchestrator writes predictions.json"
```

---

## Task 11: Vercel static hosting config

**Files:**
- Create: `web/vercel.json`

- [ ] **Step 1: Create `web/vercel.json`**

CORS so the iOS app (and any client) can fetch it; short cache so updates propagate.

```json
{
  "headers": [
    {
      "source": "/predictions.json",
      "headers": [
        { "key": "Access-Control-Allow-Origin", "value": "*" },
        { "key": "Cache-Control", "value": "public, max-age=300, s-maxage=300" }
      ]
    }
  ]
}
```

- [ ] **Step 2: Deploy to Vercel (manual, one-time)**

From the `web/` directory, link and deploy as a static project (root directory `web`, no build command, output directory `public`):

Run: `cd web && npx vercel --prod`
Follow prompts: new project, framework "Other", build command empty, output dir `public`.
Expected: a production URL. Confirm `https://<project>.vercel.app/predictions.json` returns the JSON.

- [ ] **Step 3: Record the production URL in the spec**

Edit the spec's §3 to replace the generic "Vercel" reference with the actual `https://<project>.vercel.app/predictions.json` base, so Plan 2 (iOS app) knows the exact endpoint.

Run:
```bash
cd ~/Data/Claude/worldcupp-2026-odds && git add web/vercel.json docs/superpowers/specs/2026-05-31-worldcup-odds-app-design.md
git commit -m "chore: vercel static hosting config + record JSON URL"
```

---

## Task 12: GitHub Actions cron — refresh every 6h

**Files:**
- Create: `.github/workflows/update-predictions.yml`

- [ ] **Step 1: Create the workflow**

```yaml
# .github/workflows/update-predictions.yml
name: Update predictions
on:
  schedule:
    - cron: "0 */6 * * *" # every 6 hours (2 credits/run => ~240/month, under the 500 free tier)
  workflow_dispatch: {}

permissions:
  contents: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - name: Build predictions
        working-directory: pipeline
        env:
          ODDS_API_KEY: ${{ secrets.ODDS_API_KEY }}
        run: npm run build
      - name: Commit if changed
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          if ! git diff --quiet -- web/public/predictions.json; then
            git add web/public/predictions.json
            git commit -m "data: refresh predictions [skip ci]"
            git push
          else
            echo "No change in predictions.json"
          fi
```

- [ ] **Step 2: Create the GitHub repo and add the secret**

```bash
cd ~/Data/Claude/worldcupp-2026-odds
gh repo create worldcupp-2026-odds --private --source=. --remote=origin --push
gh secret set ODDS_API_KEY --body "<your_odds_api_key>"
```
Expected: repo created, code pushed, secret stored.

- [ ] **Step 3: Trigger the workflow manually to verify**

Run: `gh workflow run "Update predictions" && sleep 30 && gh run list --limit 1`
Expected: a run appears; `gh run view` shows it succeeded and either committed a refresh or reported "No change".

- [ ] **Step 4: Commit (workflow file)**

```bash
git add .github/workflows/update-predictions.yml
git commit -m "ci: refresh predictions every 6h via github actions"
git push
```

---

## Self-Review

**Spec coverage:**
- §3 architecture (pipeline → JSON → Vercel) → Tasks 8–12. ✓
- §4 devig/Poisson/Dixon-Coles → Tasks 2–7. ✓
- §4 JSON schema (`updated`, `count`, `matches[...]`) → Task 10. ✓
- §4 cost discipline (region eu, h2h+totals, 6h cron) → Tasks 9 & 12. ✓
- iOS app (§5) → **out of scope here, intentionally** — covered by Plan 2.
- App Store compliance (§6) → Plan 2.

**Placeholder scan:** Every code step contains complete, runnable code. The only `<your_key>` placeholders are genuine user-supplied secrets, not plan gaps. ✓

**Type consistency:** `consensus1x2` returns `{home,draw,away}` (probabilities 0–1) — consumed consistently by `solveLambdas`. `marketsFromGrid` returns `{home,draw,away,over,btts}` (0–1); `transformMatch` converts to percentages via `pct()`. `topScores` returns `{score,pct}` matching the JSON schema. `transformMatch` output keys (`probs_1x2`, `top_scores`, `goal_markets.over_under_2_5`, `goal_markets.btts`) match the §4 schema exactly. ✓

---

## Definition of Done (Plan 1)

- `cd pipeline && node --test` → all green.
- `web/public/predictions.json` is valid JSON with the documented schema.
- `https://<project>.vercel.app/predictions.json` serves it with CORS.
- GitHub Actions cron is live and a manual dispatch succeeded.
- **Outcome:** a live, zero-cost predictions feed ready for the iOS app to consume in Plan 2.
