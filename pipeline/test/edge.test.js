import { test } from "node:test";
import assert from "node:assert/strict";
import { bestEdge } from "../src/edge.js";

test("bestEdge meldet die +EV-Seite oberhalb der Schwelle", () => {
  // fair home = 0.5, beste Quote 2.3 -> EV = 0.5*2.3 - 1 = 0.15 = 15%
  const e = bestEdge({ home: 0.5, draw: 0.3, away: 0.2 }, { home: 2.3, draw: 3.0, away: 4.0 });
  assert.equal(e.side, "home");
  assert.equal(e.value_pct, 15);
});

test("bestEdge gibt null, wenn keine Seite die Schwelle schlägt", () => {
  // alle EV negativ
  const e = bestEdge({ home: 0.5, draw: 0.3, away: 0.2 }, { home: 1.9, draw: 3.2, away: 4.8 });
  assert.equal(e, null);
});

test("bestEdge ignoriert Seiten ohne Quote", () => {
  const e = bestEdge({ home: 0.5, draw: 0.3, away: 0.2 }, { home: 0, draw: 0, away: 6.0 });
  assert.equal(e.side, "away"); // 0.2*6-1 = 0.2 = 20%
  assert.equal(e.value_pct, 20);
});
