// pipeline/src/oddsHistory.js
// Append one rounded daily 1X2 snapshot per match. Idempotent per (matchId, day):
// a second run on the same UTC day overwrites that day's snapshot.
// history shape: { [matchId]: [ { t: "YYYY-MM-DD", home, draw, away }, ... ] }
export function updateHistory(history, matches, isoNow) {
  const day = isoNow.slice(0, 10);
  const next = { ...history };
  for (const m of matches) {
    const snap = { t: day, home: m.probs_1x2.home, draw: m.probs_1x2.draw, away: m.probs_1x2.away };
    const series = (next[m.id] ?? []).filter((s) => s.t !== day);
    series.push(snap);
    next[m.id] = series;
  }
  return next;
}
