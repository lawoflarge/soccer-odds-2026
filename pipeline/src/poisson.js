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
