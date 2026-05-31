// pipeline/test/devig.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { devigProportional } from "../src/devig.js";

const close = (a, b, eps = 1e-4) => Math.abs(a - b) <= eps;

test("devigProportional removes the bookmaker margin and sums to 1", () => {
  const fair = devigProportional([2.1, 3.4, 3.6]); // home/draw/away
  assert.ok(close(fair[0] + fair[1] + fair[2], 1), "probs must sum to 1");
  assert.ok(close(fair[0], 0.45435), `home was ${fair[0]}`);
  assert.ok(close(fair[1], 0.28063), `draw was ${fair[1]}`);
  assert.ok(close(fair[2], 0.26502), `away was ${fair[2]}`);
});
