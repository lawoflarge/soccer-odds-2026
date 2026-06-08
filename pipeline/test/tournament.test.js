import { test } from "node:test";
import assert from "node:assert/strict";
import { phaseForDate, groupForTeam } from "../src/tournament.js";

test("phaseForDate ordnet Datum der Turnierphase zu", () => {
  assert.equal(phaseForDate("2026-06-15T19:00:00Z"), "group");
  assert.equal(phaseForDate("2026-06-29T19:00:00Z"), "round_of_32");
  assert.equal(phaseForDate("2026-07-06T19:00:00Z"), "round_of_16");
  assert.equal(phaseForDate("2026-07-19T19:00:00Z"), "final");
});

test("groupForTeam liefert die Gruppe gesetzter Gastgeber, sonst null", () => {
  assert.equal(groupForTeam("Mexico"), "A");
  assert.equal(groupForTeam("Canada"), "B");
  assert.equal(groupForTeam("United States"), "D");
  assert.equal(groupForTeam("Atlantis"), null);
});
