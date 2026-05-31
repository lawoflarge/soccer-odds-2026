// pipeline/test/transform.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { transformMatch } from "../src/transform.js";

const sample = JSON.parse(
  readFileSync(fileURLToPath(new URL("../fixtures/sample-odds.json", import.meta.url))),
);

test("transformMatch produces a complete prediction object", () => {
  const m = transformMatch(sample);
  assert.equal(m.id, "evt_demo_001");
  assert.equal(m.teams.home, "Mexico");
  assert.equal(m.teams.away, "Poland");
  assert.equal(m.kickoff, "2026-06-11T19:00:00Z");

  const { home, draw, away } = m.probs_1x2;
  assert.ok(Math.abs(home + draw + away - 100) < 0.5, "1X2 should sum to ~100");
  assert.ok(home > away, "Mexico favoured");

  assert.equal(m.top_scores.length, 5);
  assert.match(m.top_scores[0].score, /^\d+:\d+$/);

  assert.ok(m.goal_markets.over_under_2_5 >= 0 && m.goal_markets.over_under_2_5 <= 100);
  assert.ok(m.goal_markets.btts >= 0 && m.goal_markets.btts <= 100);
});

test("transformMatch returns null when h2h or totals data is missing", () => {
  const broken = { ...sample, bookmakers: [] };
  assert.equal(transformMatch(broken), null);
});

test("transformMatch returns null when commence_time is missing", () => {
  const noKickoff = { ...sample, commence_time: undefined };
  assert.equal(transformMatch(noKickoff), null);
});
