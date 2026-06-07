// pipeline/src/simulation.js
import { makePrng } from "./prng.js";
import { scoreGrid, marketsFromGrid } from "./poisson.js";

// ---------------------------------------------------------------------------
// 1. Team strength ratings from group-stage match predictions
// ---------------------------------------------------------------------------

// matches: array of match objects with { phase, teams: {home, away}, xg: {home, away} }
// Returns { [teamName]: rating } where rating is the geometric mean of all
// expected-goals observations for that team across group-stage matches.
// opts.fallback: minimum rating assigned to teams with no group data (default 0.5).
export function buildRatings(matches, opts = {}) {
  const fallback = opts.fallback ?? 0.5;
  const logSums = {};   // teamName -> { sum: number, count: number }

  for (const m of matches) {
    if (m.phase !== "group") continue;
    const { home, away } = m.teams;
    const xgH = m.xg?.home ?? fallback;
    const xgA = m.xg?.away ?? fallback;

    for (const [team, xg] of [[home, xgH], [away, xgA]]) {
      if (!logSums[team]) logSums[team] = { sum: 0, count: 0 };
      logSums[team].sum += Math.log(Math.max(xg, 0.05));
      logSums[team].count += 1;
    }
  }

  const ratings = {};
  for (const [team, { sum, count }] of Object.entries(logSums)) {
    ratings[team] = Math.max(Math.exp(sum / count), fallback);
  }
  return ratings;
}

// ---------------------------------------------------------------------------
// 2. (Implemented in Task 3+)
// ---------------------------------------------------------------------------
