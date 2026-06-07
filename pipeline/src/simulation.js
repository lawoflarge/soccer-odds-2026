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
// 2. Single-match simulation via Poisson score grid + CDF sampling
// ---------------------------------------------------------------------------

const MU_BASE = 2.5; // baseline total goals (WC average)

// Derive lambdaHome / lambdaAway from the ratio of team attack ratings.
// ratio = ratingHome / ratingAway; lambdaHome * lambdaAway = (muBase/2)^2 (approx)
// lambdaHome = (muBase/2) * sqrt(ratio), lambdaAway = (muBase/2) / sqrt(ratio)
function lambdasFromRatings(ratingHome, ratingAway, muBase = MU_BASE) {
  const half = muBase / 2;
  const sqrtRatio = Math.sqrt(Math.max(ratingHome, 0.1) / Math.max(ratingAway, 0.1));
  return {
    lambdaHome: Math.max(half * sqrtRatio, 0.1),
    lambdaAway: Math.max(half / sqrtRatio, 0.1),
  };
}

// Sample a scoreline from a Dixon-Coles Poisson grid using a single uniform draw.
// Flattens the 2D grid into a CDF and binary-searches for the sample point.
function sampleFromGrid(grid, u) {
  const max = grid.length - 1;
  let cum = 0;
  for (let x = 0; x <= max; x++) {
    for (let y = 0; y <= max; y++) {
      cum += grid[x][y];
      if (u <= cum) return { homeGoals: x, awayGoals: y };
    }
  }
  // Floating-point edge case: return last cell
  return { homeGoals: max, awayGoals: max };
}

// Simulate one match. rng is a () => [0,1) function (e.g. from makePrng).
// Returns { homeGoals: number, awayGoals: number }.
export function simulateMatch(ratingHome, ratingAway, rng, muBase = MU_BASE) {
  const { lambdaHome, lambdaAway } = lambdasFromRatings(ratingHome, ratingAway, muBase);
  const grid = scoreGrid(lambdaHome, lambdaAway);
  return sampleFromGrid(grid, rng());
}
