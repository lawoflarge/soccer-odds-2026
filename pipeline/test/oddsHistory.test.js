import { test } from "node:test";
import assert from "node:assert/strict";
import { updateHistory } from "../src/oddsHistory.js";

const matches = [{ id: "m1", probs_1x2: { home: 44, draw: 28, away: 28 } }];

test("updateHistory legt pro Match einen Tages-Snapshot an", () => {
  const h = updateHistory({}, matches, "2026-06-26T06:00:00Z");
  assert.equal(h.m1.length, 1);
  assert.deepEqual(h.m1[0], { t: "2026-06-26", home: 44, draw: 28, away: 28 });
});

test("updateHistory ist idempotent innerhalb eines Tages (überschreibt)", () => {
  let h = updateHistory({}, matches, "2026-06-26T06:00:00Z");
  h = updateHistory(h, [{ id: "m1", probs_1x2: { home: 46, draw: 27, away: 27 } }], "2026-06-26T12:00:00Z");
  assert.equal(h.m1.length, 1);
  assert.equal(h.m1[0].home, 46);
});

test("updateHistory hängt an einem neuen Tag einen Eintrag an", () => {
  let h = updateHistory({}, matches, "2026-06-26T06:00:00Z");
  h = updateHistory(h, matches, "2026-06-27T06:00:00Z");
  assert.equal(h.m1.length, 2);
});
