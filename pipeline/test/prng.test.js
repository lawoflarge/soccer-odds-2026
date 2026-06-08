import { test } from "node:test";
import assert from "node:assert/strict";
import { makePrng } from "../src/prng.js";

test("makePrng produziert deterministisch denselben Wert bei gleichem Seed", () => {
  const rng1 = makePrng(42);
  const rng2 = makePrng(42);
  const seq1 = Array.from({ length: 10 }, () => rng1());
  const seq2 = Array.from({ length: 10 }, () => rng2());
  assert.deepEqual(seq1, seq2);
});

test("makePrng produziert Werte in [0, 1)", () => {
  const rng = makePrng(99);
  for (let i = 0; i < 1000; i++) {
    const v = rng();
    assert.ok(v >= 0 && v < 1, `Wert ${v} außerhalb [0,1)`);
  }
});

test("verschiedene Seeds ergeben verschiedene erste Werte", () => {
  assert.notEqual(makePrng(1)(), makePrng(2)());
});
