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
