// pipeline/src/buildSimulation.js
// Adapter: converts predictions.json matches + GROUPS into simulation.json payload.
import { buildRatings, simulateTournament } from "./simulation.js";

// Normalize the group draw into { letter: [team, ...] } regardless of input shape.
// Accepts either { letter: [teams] } (already grouped) OR { team: letter } — the shape
// that tournament.js GROUPS actually exports and that buildPredictions.js passes.
// For the team->letter map, only teams that appear in `matches` are included, which
// naturally drops name aliases (e.g. the "United States" alias of "USA").
export function groupsByLetter(groups, matches) {
  const values = Object.values(groups);
  if (values.length && Array.isArray(values[0])) return groups; // already letter -> [teams]
  const byLetter = {};
  const seen = new Set();
  for (const m of matches) {
    for (const team of [m.teams?.home, m.teams?.away]) {
      if (!team || seen.has(team)) continue;
      seen.add(team);
      const letter = groups[team];
      if (letter) (byLetter[letter] ??= []).push(team);
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
