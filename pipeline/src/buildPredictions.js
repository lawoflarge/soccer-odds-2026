// pipeline/src/buildPredictions.js
import { writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { fetchWorldCupOdds } from "./oddsApi.js";
import { transformMatch } from "./transform.js";

const here = dirname(fileURLToPath(import.meta.url));
const OUT = resolve(here, "../../web/public/predictions.json");

async function main() {
  const apiKey = process.env.ODDS_API_KEY;
  if (!apiKey) {
    console.error("ODDS_API_KEY is not set");
    process.exit(1);
  }

  const events = await fetchWorldCupOdds(apiKey);
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
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
