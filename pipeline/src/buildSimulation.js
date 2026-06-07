// pipeline/src/buildSimulation.js
// Adapter: converts predictions.json matches + GROUPS into simulation.json payload.
import { buildRatings, simulateTournament } from "./simulation.js";

// matches: array of match objects from predictions.json (with phase, teams, xg).
// groups:  { [letter]: [team, team, team, team] } — the static group draw.
// opts:    { seed?, iterations? } — passed to simulateTournament.
// Returns the simulation.json payload object (Spec 6.3).
export function buildSimulationPayload(matches, groups, opts = {}) {
  const { iterations = 10000 } = opts;
  const ratings = buildRatings(matches);

  const { teams: teamsMap, groups: groupsMap } = simulateTournament(groups, ratings, opts);

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
