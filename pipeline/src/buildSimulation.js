// pipeline/src/buildSimulation.js
// Adapter: converts predictions.json matches + GROUPS into simulation.json payload.
import { buildRatings, simulateTournament } from "./simulation.js";

// Normalize the group draw into { letter: [team, ...] } regardless of input shape.
// Accepts either { letter: [teams] } (already grouped) OR { team: letter } — the shape
// that tournament.js GROUPS actually exports and that buildPredictions.js passes.
//
// Group membership comes from the *full static draw*, NOT from the teams that happen
// to appear in `matches`. Once the tournament is underway the Odds API only returns
// upcoming fixtures, so played group matches drop off the feed; deriving membership
// from the feed would shrink a group below its 4 teams and crash the group-stage
// simulation (which assumes complete 4-team groups). `matches` is used only to break
// alias overflow: a real FIFA group has exactly 4 teams, so the sole way a letter
// exceeds 4 is a duplicate name alias in the draw (e.g. "United States" alongside
// "USA"). Such a group is trimmed back to 4, dropping the entries the feed never
// references first (real aliases), then falling back to draw order.
export function groupsByLetter(groups, matches) {
  const values = Object.values(groups);
  if (values.length && Array.isArray(values[0])) return groups; // already letter -> [teams]

  const inFeed = new Set();
  for (const m of matches) {
    for (const team of [m.teams?.home, m.teams?.away]) if (team) inFeed.add(team);
  }

  const byLetter = {};
  for (const [team, letter] of Object.entries(groups)) (byLetter[letter] ??= []).push(team);

  for (const letter of Object.keys(byLetter)) {
    const teams = byLetter[letter];
    if (teams.length > 4) {
      // Stable sort keeps draw order within each group; in-feed teams win the cut.
      const ranked = [...teams].sort((a, b) => Number(inFeed.has(b)) - Number(inFeed.has(a)));
      byLetter[letter] = ranked.slice(0, 4);
    }
  }
  return byLetter;
}

// matches: array of match objects from predictions.json (with phase, teams, xg).
// groups:  { team: letter } (tournament.js GROUPS) OR { letter: [team,...] } — normalized internally.
// opts:    { seed?, iterations? } — passed to simulateTournament.
// Returns the simulation.json payload object (Spec 6.3).
export function buildSimulationPayload(matches, groups, opts = {}) {
  const { iterations = 10000 } = opts;
  const ratings = buildRatings(matches);

  const byLetter = groupsByLetter(groups, matches);
  const { teams: teamsMap, groups: groupsMap } = simulateTournament(byLetter, ratings, opts);

  // Convert teams map to sorted array (by win% desc)
  const teamsArr = Object.entries(teamsMap)
    .map(([team, data]) => ({ team, ...data }))
    .sort((a, b) => b.win - a.win);

  return {
    generated_at: new Date().toISOString(),
    iterations,
    teams: teamsArr,
    groups: groupsMap,
  };
}
