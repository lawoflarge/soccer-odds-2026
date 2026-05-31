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
