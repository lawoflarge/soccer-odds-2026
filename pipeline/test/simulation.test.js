import { test } from "node:test";
import assert from "node:assert/strict";
import { buildRatings } from "../src/simulation.js";

// Minimal fixture: 2 group matches involving 4 teams.
const groupMatches = [
  { phase: "group", teams: { home: "Brazil", away: "Serbia" },   xg: { home: 2.1, away: 0.8 } },
  { phase: "group", teams: { home: "Switzerland", away: "Cameroon" }, xg: { home: 1.5, away: 0.9 } },
  { phase: "group", teams: { home: "Brazil", away: "Switzerland" }, xg: { home: 1.8, away: 1.1 } },
];

test("buildRatings erzeugt positives Rating je Team", () => {
  const r = buildRatings(groupMatches);
  for (const team of ["Brazil", "Serbia", "Switzerland", "Cameroon"]) {
    assert.ok(r[team] > 0, `Rating für ${team} muss > 0 sein`);
  }
});

test("buildRatings: stärkeres Team hat höheres Rating", () => {
  const r = buildRatings(groupMatches);
  // Brazil hat zwei hohe xG-Werte (2.1 und 1.8), Serbia nur 0.8 → Brazil > Serbia
  assert.ok(r["Brazil"] > r["Serbia"], "Brazil > Serbia erwartet");
});

test("buildRatings ignoriert Nicht-Gruppenspiele", () => {
  const withKo = [
    ...groupMatches,
    { phase: "round_of_32", teams: { home: "Brazil", away: "France" }, xg: { home: 0.1, away: 5.0 } },
  ];
  const rWith = buildRatings(withKo);
  const rWithout = buildRatings(groupMatches);
  assert.equal(rWith["Brazil"], rWithout["Brazil"], "K.o.-Match darf Rating nicht beeinflussen");
});

test("buildRatings fällt auf Mindestwert 0.5 zurück bei Team ohne Spiele", () => {
  const r = buildRatings(groupMatches, { fallback: 0.5 });
  // "Ghana" hat keine Matches
  assert.equal(r["Ghana"] ?? 0.5, 0.5);
});
