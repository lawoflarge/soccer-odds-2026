// pipeline/src/simulation.js
import { makePrng } from "./prng.js";
import { scoreGrid, marketsFromGrid } from "./poisson.js";

// ---------------------------------------------------------------------------
// 1. Team strength ratings from group-stage match predictions
// ---------------------------------------------------------------------------

// matches: array of match objects with { phase, teams: {home, away}, xg: {home, away} }
// Returns { [teamName]: rating } where rating is the geometric mean of all
// expected-goals observations for that team across group-stage matches.
// opts.fallback: minimum rating assigned to teams with no group data (default 0.5).
export function buildRatings(matches, opts = {}) {
  const fallback = opts.fallback ?? 0.5;
  const logSums = {};   // teamName -> { sum: number, count: number }

  for (const m of matches) {
    if (m.phase !== "group") continue;
    const { home, away } = m.teams;
    const xgH = m.xg?.home ?? fallback;
    const xgA = m.xg?.away ?? fallback;

    for (const [team, xg] of [[home, xgH], [away, xgA]]) {
      if (!logSums[team]) logSums[team] = { sum: 0, count: 0 };
      logSums[team].sum += Math.log(Math.max(xg, 0.05));
      logSums[team].count += 1;
    }
  }

  const ratings = {};
  for (const [team, { sum, count }] of Object.entries(logSums)) {
    ratings[team] = Math.max(Math.exp(sum / count), fallback);
  }
  return ratings;
}

// ---------------------------------------------------------------------------
// 2. Single-match simulation via Poisson score grid + CDF sampling
// ---------------------------------------------------------------------------

const MU_BASE = 2.5; // baseline total goals (WC average)

// Derive lambdaHome / lambdaAway from the ratio of team attack ratings.
// ratio = ratingHome / ratingAway; lambdaHome * lambdaAway = (muBase/2)^2 (approx)
// lambdaHome = (muBase/2) * sqrt(ratio), lambdaAway = (muBase/2) / sqrt(ratio)
function lambdasFromRatings(ratingHome, ratingAway, muBase = MU_BASE) {
  const half = muBase / 2;
  const sqrtRatio = Math.sqrt(Math.max(ratingHome, 0.1) / Math.max(ratingAway, 0.1));
  return {
    lambdaHome: Math.max(half * sqrtRatio, 0.1),
    lambdaAway: Math.max(half / sqrtRatio, 0.1),
  };
}

// Sample a scoreline from a Dixon-Coles Poisson grid using a single uniform draw.
// Flattens the 2D grid into a CDF and binary-searches for the sample point.
function sampleFromGrid(grid, u) {
  const max = grid.length - 1;
  let cum = 0;
  for (let x = 0; x <= max; x++) {
    for (let y = 0; y <= max; y++) {
      cum += grid[x][y];
      if (u <= cum) return { homeGoals: x, awayGoals: y };
    }
  }
  // Floating-point edge case: return last cell
  return { homeGoals: max, awayGoals: max };
}

// Simulate one match. rng is a () => [0,1) function (e.g. from makePrng).
// Returns { homeGoals: number, awayGoals: number }.
export function simulateMatch(ratingHome, ratingAway, rng, muBase = MU_BASE) {
  const { lambdaHome, lambdaAway } = lambdasFromRatings(ratingHome, ratingAway, muBase);
  const grid = scoreGrid(lambdaHome, lambdaAway);
  return sampleFromGrid(grid, rng());
}

// ---------------------------------------------------------------------------
// 3. Group-stage simulation (4-team round-robin, 6 matches)
// ---------------------------------------------------------------------------

// Rank teams within a group by: pts desc, gd desc, gf desc, then coin flip.
function rankGroup(table, rng) {
  const arr = Object.entries(table).map(([team, s]) => ({ team, ...s }));
  arr.sort((a, b) => {
    if (b.pts !== a.pts) return b.pts - a.pts;
    if (b.gd  !== a.gd)  return b.gd  - a.gd;
    if (b.gf  !== a.gf)  return b.gf  - a.gf;
    return rng() < 0.5 ? -1 : 1; // coin flip
  });
  return arr.map((r, i) => ({ ...r, rank: i + 1 }));
}

// teams: string[4], ratings: { [team]: number }, rng: () => [0,1)
// Returns sorted array [{ team, pts, gd, gf, rank }, ...] length 4.
export function simulateGroup(teams, ratings, rng) {
  const table = {};
  for (const t of teams) table[t] = { pts: 0, gd: 0, gf: 0 };

  // All 6 pairings in a 4-team group
  for (let i = 0; i < teams.length; i++) {
    for (let j = i + 1; j < teams.length; j++) {
      const home = teams[i];
      const away = teams[j];
      const { homeGoals, awayGoals } = simulateMatch(ratings[home] ?? 1.0, ratings[away] ?? 1.0, rng);

      table[home].gf += homeGoals;
      table[away].gf += awayGoals;
      table[home].gd += homeGoals - awayGoals;
      table[away].gd += awayGoals - homeGoals;

      if (homeGoals > awayGoals) {
        table[home].pts += 3;
      } else if (homeGoals === awayGoals) {
        table[home].pts += 1;
        table[away].pts += 1;
      } else {
        table[away].pts += 3;
      }
    }
  }

  return rankGroup(table, rng);
}

// ---------------------------------------------------------------------------
// 4. Best-8 third-place selection (FIFA WC 2026 rule)
// ---------------------------------------------------------------------------

// thirds: array of { team, pts, gd, gf } (one per group, length 12)
// Returns the 8 best by: pts desc, gd desc, gf desc.
export function selectBestThirds(thirds) {
  return [...thirds]
    .sort((a, b) => {
      if (b.pts !== a.pts) return b.pts - a.pts;
      if (b.gd  !== a.gd)  return b.gd  - a.gd;
      if (b.gf  !== a.gf)  return b.gf  - a.gf;
      return 0;
    })
    .slice(0, 8);
}

// ---------------------------------------------------------------------------
// 5. Knockout-stage simulation (single-elimination, coin flip on draw)
// ---------------------------------------------------------------------------

// bracket: array of [teamA, teamB] pairings for this round.
// Returns the array of winners.
function simulateRound(bracket, ratings, rng) {
  const winners = [];
  for (const [a, b] of bracket) {
    const { homeGoals, awayGoals } = simulateMatch(ratings[a] ?? 1.0, ratings[b] ?? 1.0, rng);
    if (homeGoals > awayGoals) {
      winners.push(a);
    } else if (awayGoals > homeGoals) {
      winners.push(b);
    } else {
      winners.push(rng() < 0.5 ? a : b); // coin flip on draw
    }
  }
  return winners;
}

// Pair adjacent winners: [0,1], [2,3], [4,5], ...
function makePairs(teams) {
  const pairs = [];
  for (let i = 0; i < teams.length; i += 2) pairs.push([teams[i], teams[i + 1]]);
  return pairs;
}

// ---------------------------------------------------------------------------
// 6. Full tournament simulation
// ---------------------------------------------------------------------------

// groups: { [letter]: [team1, team2, team3, team4] } — team order = pot order (not rank)
// ratings: { [teamName]: number }
// opts: { seed?, iterations?, bracketOrder? }
// Returns: {
//   teams: { [teamName]: { win, reach: { r32, r16, qf, sf, final, title } } },
//   groups: { [letter]: [ { team, advance, win_group }, ... ] }
// }
export function simulateTournament(groups, ratings, opts = {}) {
  const { seed = 0, iterations = 10000 } = opts;
  const rng = makePrng(seed);

  const groupLetters = Object.keys(groups).sort();
  const allTeams = groupLetters.flatMap((g) => groups[g]);

  // Accumulators
  const reachCount = {};
  const groupAdvanceCount = {}; // [groupLetter][team] -> count advanced (top 2 or best 3rd)
  const groupWinCount = {};     // [groupLetter][team] -> count won group (rank 1)

  for (const t of allTeams) {
    reachCount[t] = { r32: 0, r16: 0, qf: 0, sf: 0, final: 0, title: 0 };
  }
  for (const g of groupLetters) {
    groupAdvanceCount[g] = {};
    groupWinCount[g] = {};
    for (const t of groups[g]) {
      groupAdvanceCount[g][t] = 0;
      groupWinCount[g][t] = 0;
    }
  }

  for (let iter = 0; iter < iterations; iter++) {
    // --- Group stage ---
    const groupResults = {};   // letter -> ranked array [{team, pts, gd, gf, rank}]
    const allThirds = [];

    for (const letter of groupLetters) {
      const ranked = simulateGroup(groups[letter], ratings, rng);
      groupResults[letter] = ranked;
      allThirds.push({ ...ranked[2], groupLetter: letter });
    }

    // Determine best 8 third-placed teams
    const best8Thirds = selectBestThirds(allThirds);
    const best8Set = new Set(best8Thirds.map((t) => t.team));

    // Mark advancement
    for (const letter of groupLetters) {
      const ranked = groupResults[letter];
      // Rank 1 and 2 always advance
      groupAdvanceCount[letter][ranked[0].team]++;
      groupAdvanceCount[letter][ranked[1].team]++;
      groupWinCount[letter][ranked[0].team]++;
      // Rank 3 advances only if in best-8
      if (best8Set.has(ranked[2].team)) {
        groupAdvanceCount[letter][ranked[2].team]++;
      }
    }

    // Build R32 participant list (32 teams):
    // 12 group winners + 12 runners-up + 8 best thirds = 32
    const r32Teams = [];
    for (const letter of groupLetters) {
      r32Teams.push(groupResults[letter][0].team); // winner
    }
    for (const letter of groupLetters) {
      r32Teams.push(groupResults[letter][1].team); // runner-up
    }
    for (const t of best8Thirds) r32Teams.push(t.team);

    // Mark r32 reached
    for (const t of r32Teams) reachCount[t].r32++;

    // K.o. rounds: R32 (32→16), R16 (16→8), QF (8→4), SF (4→2), Final (2→1)
    const roundKeys = ["r16", "qf", "sf", "final", "title"];
    let current = r32Teams; // 32 teams

    for (let round = 0; round < roundKeys.length; round++) {
      const pairs = makePairs(current);
      const winners = simulateRound(pairs, ratings, rng);
      const key = roundKeys[round];
      for (const t of winners) reachCount[t][key]++;
      current = winners;
    }
    // current[0] is the champion — already counted in title above
  }

  // Aggregate to percentages
  const teamsOut = {};
  for (const t of allTeams) {
    const r = reachCount[t];
    teamsOut[t] = {
      win: Math.round((r.title / iterations) * 1000) / 10,
      reach: {
        r32:   Math.round((r.r32   / iterations) * 1000) / 10,
        r16:   Math.round((r.r16   / iterations) * 1000) / 10,
        qf:    Math.round((r.qf    / iterations) * 1000) / 10,
        sf:    Math.round((r.sf    / iterations) * 1000) / 10,
        final: Math.round((r.final / iterations) * 1000) / 10,
        title: Math.round((r.title / iterations) * 1000) / 10,
      },
    };
  }

  const groupsOut = {};
  for (const letter of groupLetters) {
    groupsOut[letter] = groups[letter].map((team) => ({
      team,
      advance:   Math.round((groupAdvanceCount[letter][team] / iterations) * 1000) / 10,
      win_group: Math.round((groupWinCount[letter][team]     / iterations) * 1000) / 10,
    }));
  }

  return { teams: teamsOut, groups: groupsOut };
}
