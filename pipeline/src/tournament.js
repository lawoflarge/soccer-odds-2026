// pipeline/src/tournament.js
// Tournament phase derived from the UTC kickoff date (FIFA WC 2026 calendar).
const PHASE_BOUNDARIES = [
  { until: "2026-06-28", phase: "group" },
  { until: "2026-07-04", phase: "round_of_32" },
  { until: "2026-07-08", phase: "round_of_16" },
  { until: "2026-07-12", phase: "qf" },
  { until: "2026-07-16", phase: "sf" },
  { until: "2026-07-19", phase: "third" },
];

export function phaseForDate(isoKickoff) {
  const day = isoKickoff.slice(0, 10);
  for (const b of PHASE_BOUNDARIES) if (day < b.until) return b.phase;
  return "final";
}

// Team display name -> group letter. Official FIFA World Cup 2026 final draw
// (5 Dec 2025 + March 2026 playoffs), validated against Wikipedia/NBC/Yahoo.
// Keys match the exact Odds API strings in web/public/predictions.json.
export const GROUPS = {
  // Group A
  "Czech Republic": "A",
  "Mexico": "A",
  "South Africa": "A",
  "South Korea": "A",
  // Group B
  "Bosnia & Herzegovina": "B",
  "Canada": "B",
  "Qatar": "B",
  "Switzerland": "B",
  // Group C
  "Brazil": "C",
  "Haiti": "C",
  "Morocco": "C",
  "Scotland": "C",
  // Group D
  "Australia": "D",
  "Paraguay": "D",
  "Turkey": "D",
  "USA": "D",
  "United States": "D", // alias: Odds API feed uses "USA"; kept so the seeded-host test stays valid
  // Group E
  "Curaçao": "E",
  "Ecuador": "E",
  "Germany": "E",
  "Ivory Coast": "E",
  // Group F
  "Japan": "F",
  "Netherlands": "F",
  "Sweden": "F",
  "Tunisia": "F",
  // Group G
  "Belgium": "G",
  "Egypt": "G",
  "Iran": "G",
  "New Zealand": "G",
  // Group H
  "Cape Verde": "H",
  "Saudi Arabia": "H",
  "Spain": "H",
  "Uruguay": "H",
  // Group I
  "France": "I",
  "Iraq": "I",
  "Norway": "I",
  "Senegal": "I",
  // Group J
  "Algeria": "J",
  "Argentina": "J",
  "Austria": "J",
  "Jordan": "J",
  // Group K
  "Colombia": "K",
  "DR Congo": "K",
  "Portugal": "K",
  "Uzbekistan": "K",
  // Group L
  "Croatia": "L",
  "England": "L",
  "Ghana": "L",
  "Panama": "L",
};

export function groupForTeam(team) {
  return GROUPS[team] ?? null;
}
