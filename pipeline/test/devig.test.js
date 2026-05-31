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

import { consensus1x2, consensusOver } from "../src/devig.js";

test("consensus1x2 averages devigged probabilities across books", () => {
  const books = [
    [2.1, 3.4, 3.6],
    [2.05, 3.5, 3.7],
  ];
  const c = consensus1x2(books);
  assert.ok(close(c.home + c.draw + c.away, 1), "consensus must sum to 1");
  assert.ok(c.home > c.away, "home favourite should have higher prob");
});

test("consensusOver averages devigged over-2.5 probability across books", () => {
  // each book: [overOdds, underOdds]
  const books = [
    [1.9, 1.9],
    [2.0, 1.8],
  ];
  const over = consensusOver(books);
  assert.ok(over > 0 && over < 1, `over was ${over}`);
  assert.ok(close(over, 0.4862, 1e-3), `over was ${over}`);
});
