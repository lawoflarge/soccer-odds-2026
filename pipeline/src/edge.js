// pipeline/src/edge.js
// Best +EV side comparing fair model probabilities against the best available odds.
// fairProbs: { home, draw, away } as fractions (0..1)
// bestOdds:  { home, draw, away } highest decimal odds offered across books (0 if none)
// Returns { side, value_pct } for the highest +EV side >= thresholdPct, else null.
export function bestEdge(fairProbs, bestOdds, thresholdPct = 2) {
  let best = null;
  for (const side of ["home", "draw", "away"]) {
    const odds = bestOdds[side];
    if (!odds) continue;
    const ev = fairProbs[side] * odds - 1;
    const pct = Math.round(ev * 1000) / 10;
    if (best === null || pct > best.value_pct) best = { side, value_pct: pct };
  }
  if (!best || best.value_pct < thresholdPct) return null;
  return best;
}
