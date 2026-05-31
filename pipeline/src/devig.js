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
