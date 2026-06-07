// pipeline/src/buildPredictions.js
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { fetchWorldCupOdds } from "./oddsApi.js";
import { transformMatch } from "./transform.js";
import { updateHistory } from "./oddsHistory.js";
import { buildSimulationPayload } from "./buildSimulation.js";
import { GROUPS } from "./tournament.js";
import { computeTrackRecord } from "./trackRecord.js";

const here = dirname(fileURLToPath(import.meta.url));
const OUT       = resolve(here, "../../web/public/predictions.json");
const HIST      = resolve(here, "../../web/public/odds_history.json");
const SIM_OUT   = resolve(here, "../../web/public/simulation.json");
const TRACK_OUT = resolve(here, "../../web/public/track_record.json");

async function main() {
  const apiKey = process.env.ODDS_API_KEY;
  if (!apiKey) {
    console.error("ODDS_API_KEY is not set");
    process.exit(1);
  }

  // --- Fetch + transform ---
  const events = await fetchWorldCupOdds(apiKey);
  if (!Array.isArray(events))
    throw new Error(`Unexpected Odds API response: ${JSON.stringify(events).slice(0, 200)}`);
  const matches = events.map(transformMatch).filter(Boolean);
  matches.sort((a, b) => a.kickoff.localeCompare(b.kickoff));

  const now = new Date().toISOString();
  const payload = { updated: now, count: matches.length, matches };

  mkdirSync(dirname(OUT), { recursive: true });
  writeFileSync(OUT, JSON.stringify(payload, null, 2) + "\n");
  console.error(`Wrote ${matches.length} matches to ${OUT}`);

  // --- Odds history ---
  const prevHist = existsSync(HIST) ? JSON.parse(readFileSync(HIST, "utf8")) : {};
  const hist = updateHistory(prevHist, matches, now);
  writeFileSync(HIST, JSON.stringify(hist) + "\n");
  console.error(`Updated odds history for ${matches.length} matches`);

  // --- Monte-Carlo simulation ---
  const simPayload = buildSimulationPayload(matches, GROUPS, { iterations: 10000 });
  writeFileSync(SIM_OUT, JSON.stringify(simPayload, null, 2) + "\n");
  console.error(`Wrote simulation.json (${simPayload.iterations} iterations, ${simPayload.teams.length} teams)`);

  // --- Track record (conditional) ---
  const settledFile = process.env.SETTLED_FILE;
  if (settledFile && existsSync(settledFile)) {
    const settled = JSON.parse(readFileSync(settledFile, "utf8"));
    const tr = computeTrackRecord(settled);
    if (tr) {
      writeFileSync(TRACK_OUT, JSON.stringify(tr, null, 2) + "\n");
      console.error(`Wrote track_record.json (${tr.settled_matches} settled matches)`);
    }
  } else {
    console.error("SETTLED_FILE not set or not found — skipping track_record.json");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
