// pipeline/src/trackRecord.js
// Pure function: compute Brier score + hit rate per market from settled match records.
//
// settled: array of { prediction, result }
//   prediction.probs_1x2: { home, draw, away }  (pct, 0..100)
//   prediction.goal_markets: { over_under_2_5, btts }  (pct, 0..100)
//   result: { home_goals, away_goals }
//
// Returns: Spec-6.4 track_record object, or null if settled is empty.
export function computeTrackRecord(settled) {
  if (!settled || settled.length === 0) return null;

  const markets = {
    "1x2":      { bsSum: 0, hits: 0, n: 0 },
    "over_2_5": { bsSum: 0, hits: 0, n: 0 },
    "btts":     { bsSum: 0, hits: 0, n: 0 },
  };

  for (const { prediction, result } of settled) {
    const { home_goals, away_goals } = result;
    const { probs_1x2, goal_markets } = prediction;

    // --- 1x2 ---
    const pH = probs_1x2.home / 100;
    const pD = probs_1x2.draw / 100;
    const pA = probs_1x2.away / 100;

    // Outcome one-hot vector
    const oH = home_goals > away_goals ? 1 : 0;
    const oD = home_goals === away_goals ? 1 : 0;
    const oA = home_goals < away_goals ? 1 : 0;

    const bs1x2 = (pH - oH) ** 2 + (pD - oD) ** 2 + (pA - oA) ** 2;
    markets["1x2"].bsSum += bs1x2;
    markets["1x2"].n++;

    // Hit: predicted outcome (max prob) matches actual outcome
    const predSide = pH >= pD && pH >= pA ? "home" : pD >= pA ? "draw" : "away";
    const actualSide = oH ? "home" : oD ? "draw" : "away";
    if (predSide === actualSide) markets["1x2"].hits++;

    // --- over_2_5 ---
    if (goal_markets?.over_under_2_5 != null) {
      const pO = goal_markets.over_under_2_5 / 100;
      const oO = home_goals + away_goals >= 3 ? 1 : 0;
      markets["over_2_5"].bsSum += (pO - oO) ** 2;
      markets["over_2_5"].n++;
      if ((pO >= 0.5) === (oO === 1)) markets["over_2_5"].hits++;
    }

    // --- btts ---
    if (goal_markets?.btts != null) {
      const pB = goal_markets.btts / 100;
      const oB = home_goals >= 1 && away_goals >= 1 ? 1 : 0;
      markets["btts"].bsSum += (pB - oB) ** 2;
      markets["btts"].n++;
      if ((pB >= 0.5) === (oB === 1)) markets["btts"].hits++;
    }
  }

  const round3 = (x) => Math.round(x * 1000) / 1000;

  const by_market = {};
  for (const [key, m] of Object.entries(markets)) {
    if (m.n === 0) continue;
    by_market[key] = {
      n:        m.n,
      brier:    round3(m.bsSum / m.n),
      hit_rate: round3(m.hits / m.n),
    };
  }

  return {
    updated_at: new Date().toISOString(),
    settled_matches: settled.length,
    by_market,
  };
}
