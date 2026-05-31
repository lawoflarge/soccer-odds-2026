// pipeline/src/oddsApi.js
const BASE = "https://api.the-odds-api.com/v4";
const SPORT = "soccer_fifa_world_cup";

// Fetch World Cup odds: region=eu, markets=h2h,totals (2 credits/call).
// Returns the parsed array of events.
export async function fetchWorldCupOdds(apiKey) {
  const url =
    `${BASE}/sports/${SPORT}/odds/` +
    `?apiKey=${apiKey}&regions=eu&markets=h2h,totals&oddsFormat=decimal`;
  const res = await fetch(url);
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Odds API ${res.status}: ${body}`);
  }
  const remaining = res.headers.get("x-requests-remaining");
  if (remaining !== null) console.error(`Odds API credits remaining: ${remaining}`);
  return res.json();
}
