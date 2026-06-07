import { test } from "node:test";
import assert from "node:assert/strict";
import { computeTrackRecord } from "../src/trackRecord.js";

// Perfect 1x2 prediction: home=100%, result home win
const perfectHome = {
  prediction: { probs_1x2: { home: 100, draw: 0, away: 0 }, goal_markets: { over_under_2_5: 100, btts: 0 } },
  result: { home_goals: 2, away_goals: 1 },
};

// Random 1x2 prediction (33.3% each), result draw
const random = {
  prediction: { probs_1x2: { home: 33.3, draw: 33.3, away: 33.4 }, goal_markets: { over_under_2_5: 50, btts: 50 } },
  result: { home_goals: 1, away_goals: 1 },
};

test("computeTrackRecord: perfekte Prognose hat Brier 0 für 1x2", () => {
  const tr = computeTrackRecord([perfectHome]);
  assert.equal(tr.by_market["1x2"].brier, 0);
  assert.equal(tr.by_market["1x2"].hit_rate, 1);
  assert.equal(tr.settled_matches, 1);
});

test("computeTrackRecord: Brier-Score für Zufallsprognose ist ~0.667 (1x2)", () => {
  const tr = computeTrackRecord([random]);
  // BS for draw result: (0.333-0)² + (0.333-1)² + (0.334-0)² ≈ 0.111 + 0.444 + 0.112 = 0.667
  assert.ok(Math.abs(tr.by_market["1x2"].brier - 0.667) < 0.01, `brier=${tr.by_market["1x2"].brier}`);
});

test("computeTrackRecord: hit_rate 0 wenn falsche Seite vorhergesagt", () => {
  const wrongPred = {
    prediction: { probs_1x2: { home: 80, draw: 10, away: 10 }, goal_markets: { over_under_2_5: 50, btts: 50 } },
    result: { home_goals: 0, away_goals: 1 }, // away win
  };
  const tr = computeTrackRecord([wrongPred]);
  assert.equal(tr.by_market["1x2"].hit_rate, 0);
});

test("computeTrackRecord: over_2_5 market korrekt", () => {
  const tr = computeTrackRecord([perfectHome]); // 2+1=3 goals, over_2_5=true; pred=100%
  assert.equal(tr.by_market["over_2_5"].brier, 0);
  assert.equal(tr.by_market["over_2_5"].hit_rate, 1);
});

test("computeTrackRecord: leere Liste gibt null zurück", () => {
  const tr = computeTrackRecord([]);
  assert.equal(tr, null);
});

test("computeTrackRecord: mehrere Matches werden korrekt gemittelt", () => {
  const tr = computeTrackRecord([perfectHome, random]);
  assert.equal(tr.settled_matches, 2);
  assert.ok(tr.by_market["1x2"].n === 2);
  assert.ok(tr.by_market["1x2"].brier >= 0 && tr.by_market["1x2"].brier <= 2);
});
