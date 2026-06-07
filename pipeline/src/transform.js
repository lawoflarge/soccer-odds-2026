// pipeline/src/transform.js
import { consensus1x2, consensusOver } from "./devig.js";
import { solveLambdas, scoreGrid, marketsFromGrid, topScores, extraGoalMarkets } from "./poisson.js";
import { bestEdge } from "./edge.js";
import { phaseForDate, groupForTeam } from "./tournament.js";

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

// Highest decimal odds offered for each 1X2 side across all books.
function bestH2hOdds(event) {
  const best = { home: 0, draw: 0, away: 0 };
  for (const b of event.bookmakers ?? []) {
    const mkt = b.markets?.find((m) => m.key === "h2h");
    if (!mkt) continue;
    const h = mkt.outcomes.find((o) => o.name === event.home_team)?.price;
    const a = mkt.outcomes.find((o) => o.name === event.away_team)?.price;
    const d = mkt.outcomes.find((o) => o.name === "Draw")?.price;
    if (h) best.home = Math.max(best.home, h);
    if (d) best.draw = Math.max(best.draw, d);
    if (a) best.away = Math.max(best.away, a);
  }
  return best;
}

// Map one Odds API event to a prediction object, or null if data is insufficient.
export function transformMatch(event) {
  const h2h = h2hBooks(event);
  const totals = totalsBooks(event);
  if (h2h.length === 0 || totals.length === 0) return null;
  if (!event.commence_time) return null;

  const c = consensus1x2(h2h);
  const over = consensusOver(totals);

  const { lambdaHome, lambdaAway } = solveLambdas(c, over);
  const grid = scoreGrid(lambdaHome, lambdaAway);
  const m = marketsFromGrid(grid);
  const ext = extraGoalMarkets(grid);
  const phase = phaseForDate(event.commence_time);

  return {
    id: event.id,
    teams: { home: event.home_team, away: event.away_team },
    kickoff: event.commence_time,
    phase,
    group: phase === "group" ? groupForTeam(event.home_team) : null,
    probs_1x2: { home: pct(m.home), draw: pct(m.draw), away: pct(m.away) },
    top_scores: topScores(grid, 5),
    goal_markets: { over_under_2_5: pct(m.over), btts: pct(m.btts) },
    xg: { home: Math.round(lambdaHome * 100) / 100, away: Math.round(lambdaAway * 100) / 100 },
    markets_ext: {
      over_1_5: pct(ext.over_1_5),
      over_3_5: pct(ext.over_3_5),
      correct_score: topScores(grid, 10),
    },
    edge: bestEdge(c, bestH2hOdds(event)),
  };
}
