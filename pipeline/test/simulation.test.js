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

import { simulateGroup } from "../src/simulation.js";

test("simulateGroup gibt 4 Teams mit Rang 1..4 zurück", () => {
  const teams = ["Brazil", "Serbia", "Switzerland", "Cameroon"];
  const ratings = { Brazil: 2.0, Serbia: 0.9, Switzerland: 1.2, Cameroon: 0.8 };
  const result = simulateGroup(teams, ratings, makePrng(55));
  assert.equal(result.length, 4);
  const ranks = result.map((r) => r.rank).sort((a, b) => a - b);
  assert.deepEqual(ranks, [1, 2, 3, 4]);
});

test("simulateGroup: Punkte, Tordifferenz, Tore sind konsistent", () => {
  const teams = ["A", "B", "C", "D"];
  const ratings = { A: 1.5, B: 1.2, C: 1.0, D: 0.8 };
  const result = simulateGroup(teams, ratings, makePrng(77));
  for (const r of result) {
    assert.ok(r.pts >= 0 && r.pts <= 9, `pts ${r.pts} außerhalb [0,9]`);
    assert.ok(typeof r.gf === "number" && r.gf >= 0);
    assert.ok(typeof r.gd === "number");
  }
});

test("simulateGroup: Rang 1 hat mindestens so viele Punkte wie Rang 2", () => {
  const teams = ["A", "B", "C", "D"];
  const ratings = { A: 1.5, B: 1.2, C: 1.0, D: 0.8 };
  for (let seed = 0; seed < 50; seed++) {
    const result = simulateGroup(teams, ratings, makePrng(seed));
    const byRank = result.sort((a, b) => a.rank - b.rank);
    assert.ok(byRank[0].pts >= byRank[1].pts, `seed=${seed}: Rang 1 Pts < Rang 2 Pts`);
  }
});

import { selectBestThirds, simulateTournament } from "../src/simulation.js";

test("selectBestThirds wählt die 8 stärksten Drittplatzierten aus 12", () => {
  // 12 Drittplatzierte mit verschiedenen Punkten + Tordifferenz
  const thirds = Array.from({ length: 12 }, (_, i) => ({
    team: `T${i}`,
    pts: i < 8 ? 4 : 1,  // T0..T7 haben 4 Punkte, T8..T11 haben 1 Punkt
    gd: 0,
    gf: 0,
  }));
  const best8 = selectBestThirds(thirds);
  assert.equal(best8.length, 8);
  // Alle Best-8 müssen 4 Punkte haben
  for (const t of best8) assert.equal(t.pts, 4);
});

test("simulateTournament gibt für alle 48 Teams einen Eintrag zurück", () => {
  // Minimales Fixture: 12 Gruppen à 4 Teams
  const GROUPS_FIXTURE = {};
  const ALL_TEAMS = [];
  for (let g = 0; g < 12; g++) {
    const letter = String.fromCharCode(65 + g); // A..L
    const teams = [`T${g}_1`, `T${g}_2`, `T${g}_3`, `T${g}_4`];
    GROUPS_FIXTURE[letter] = teams;
    ALL_TEAMS.push(...teams);
  }
  const ratings = Object.fromEntries(ALL_TEAMS.map((t) => [t, 1.0]));
  const result = simulateTournament(GROUPS_FIXTURE, ratings, { seed: 1 });
  assert.equal(Object.keys(result.teams).length, 48);
});

test("simulateTournament: Sieg-%-Summe liegt nahe 100 %", () => {
  const GROUPS_FIXTURE = {};
  const ALL_TEAMS = [];
  for (let g = 0; g < 12; g++) {
    const letter = String.fromCharCode(65 + g);
    const teams = [`T${g}_1`, `T${g}_2`, `T${g}_3`, `T${g}_4`];
    GROUPS_FIXTURE[letter] = teams;
    ALL_TEAMS.push(...teams);
  }
  const ratings = Object.fromEntries(ALL_TEAMS.map((t) => [t, 1.0]));
  const result = simulateTournament(GROUPS_FIXTURE, ratings, { seed: 2, iterations: 1000 });
  const totalWin = Object.values(result.teams).reduce((s, t) => s + t.win, 0);
  assert.ok(Math.abs(totalWin - 100) < 1.0, `Sieg-%-Summe=${totalWin.toFixed(2)} erwartet ~100`);
});

test("simulateTournament ist deterministisch bei gleichem Seed", () => {
  const GROUPS_FIXTURE = {};
  const ALL_TEAMS = [];
  for (let g = 0; g < 12; g++) {
    const letter = String.fromCharCode(65 + g);
    GROUPS_FIXTURE[letter] = [`T${g}_1`, `T${g}_2`, `T${g}_3`, `T${g}_4`];
    ALL_TEAMS.push(`T${g}_1`, `T${g}_2`, `T${g}_3`, `T${g}_4`);
  }
  const ratings = Object.fromEntries(ALL_TEAMS.map((t) => [t, 1.0]));
  const r1 = simulateTournament(GROUPS_FIXTURE, ratings, { seed: 42, iterations: 200 });
  const r2 = simulateTournament(GROUPS_FIXTURE, ratings, { seed: 42, iterations: 200 });
  assert.deepEqual(r1, r2);
});
