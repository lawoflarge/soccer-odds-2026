// pipeline/src/buildPredictions.js
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { fetchWorldCupOdds } from "./oddsApi.js";
import { transformMatch } from "./transform.js";
import { updateHistory } from "./oddsHistory.js";

const here = dirname(fileURLToPath(import.meta.url));
const OUT = resolve(here, "../../web/public/predictions.json");
const HIST = resolve(here, "../../web/public/odds_history.json");

async function main() {
  const apiKey = process.env.ODDS_API_KEY;
  if (!apiKey) {
    console.error("ODDS_API_KEY is not set");
    process.exit(1);
  }

  const events = await fetchWorldCupOdds(apiKey);
  if (!Array.isArray(events))
    throw new Error(`Unexpected Odds API response: ${JSON.stringify(events).slice(0, 200)}`);
  const matches = events.map(transformMatch).filter(Boolean);
  // Stable ordering by kickoff so diffs are minimal between runs.
  matches.sort((a, b) => a.kickoff.localeCompare(b.kickoff));

  const payload = {
    updated: new Date().toISOString(),
    count: matches.length,
    matches,
  };

  mkdirSync(dirname(OUT), { recursive: true });
  writeFileSync(OUT, JSON.stringify(payload, null, 2) + "\n");
  console.error(`Wrote ${matches.length} matches to ${OUT}`);

  // Accumulate the daily odds-movement history.
  const prevHist = existsSync(HIST) ? JSON.parse(readFileSync(HIST, "utf8")) : {};
  const hist = updateHistory(prevHist, matches, payload.updated);
  writeFileSync(HIST, JSON.stringify(hist) + "\n");
  console.error(`Updated odds history for ${matches.length} matches at ${HIST}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
