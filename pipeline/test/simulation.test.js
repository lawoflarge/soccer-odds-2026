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

import { simulateMatch } from "../src/simulation.js";
import { makePrng } from "../src/prng.js";

test("simulateMatch gibt ganze nicht-negative Tore zurück", () => {
  const rng = makePrng(7);
  for (let i = 0; i < 200; i++) {
    const { homeGoals, awayGoals } = simulateMatch(1.5, 1.0, rng);
    assert.ok(Number.isInteger(homeGoals) && homeGoals >= 0, `homeGoals=${homeGoals}`);
    assert.ok(Number.isInteger(awayGoals) && awayGoals >= 0, `awayGoals=${awayGoals}`);
  }
});

test("simulateMatch: stärkeres Team gewinnt öfter in 10.000 Durchläufen", () => {
  const rng = makePrng(13);
  let homeWins = 0;
  for (let i = 0; i < 10000; i++) {
    const { homeGoals, awayGoals } = simulateMatch(2.5, 0.5, rng);
    if (homeGoals > awayGoals) homeWins++;
  }
  assert.ok(homeWins > 7000, `HomeWins=${homeWins} erwartet > 7000 (sehr starkes Heimteam)`);
});

test("simulateMatch ist deterministisch bei gleichem Seed", () => {
  const seq1 = Array.from({ length: 5 }, () => simulateMatch(1.2, 1.0, makePrng(42)));
  const seq2 = Array.from({ length: 5 }, () => simulateMatch(1.2, 1.0, makePrng(42)));
  assert.deepEqual(seq1, seq2);
});
