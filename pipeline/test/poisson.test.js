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
