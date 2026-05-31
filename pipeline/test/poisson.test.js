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
