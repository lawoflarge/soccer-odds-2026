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

// Team display name -> group letter, from the official FIFA 2026 draw.
// Seeded hosts are fixed; remaining 45 teams to be filled in Step 6.
export const GROUPS = {
  Mexico: "A",
  Canada: "B",
  "United States": "D",
};

export function groupForTeam(team) {
  return GROUPS[team] ?? null;
}
