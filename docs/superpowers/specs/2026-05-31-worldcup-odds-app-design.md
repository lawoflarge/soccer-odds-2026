# World Cup 2026 Odds — Design Spec

**Date:** 2026-05-31
**Status:** Approved design, pending implementation plan
**App name / GitHub repo / local folder:** `World Cup 2026 Odds` (repo & folder: `world-cup-2026-odds`). The name uses the protected mark directly — see §6.7 for the FIFA trademark risk and its mitigations.

## 1. Summary

A lightweight **English-language iOS app** for the FIFA World Cup 2026 (kickoff June 11, 2026). For each of the 104 matches it shows the **market-consensus prediction** derived from bookmaker odds: win/draw/win probabilities, most likely scorelines, and goal markets. Users can pick a favorite team and follow its predicted tournament path. Purely informational/entertainment — no betting, no real-money gaming.

The app reads a pre-computed static JSON file; all odds-fetching and probability math happens centrally in a scheduled job, so running cost is **0 €** regardless of download count.

### Goals
- Help users estimate how to predict matches (e.g. for Kicktipp / bracket pools) by showing what the betting market expects.
- Let users follow their favorite team's likely performance through the tournament.
- Ship before/around the World Cup with guaranteed zero running cost.

### Non-Goals (YAGNI)
- No expected-points / pool-game-theory optimizer (considered and explicitly dropped).
- No B2B odds API.
- No betting, wagering, or affiliate/bookmaker links.
- No leagues beyond the World Cup (no Bundesliga/CL). WM 2026 only.
- No backend database (no Supabase). No user accounts.
- No live in-play second-by-second updates (pre-match consensus is sufficient).
- No localization in v1 (English only).

## 2. Key Decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Direction | Consensus viewer (show probable outcome) | User's explicit preference; simple, personal-use friendly |
| Scope | World Cup 2026 only (104 matches) | Fits ~11-day window; tight, shippable |
| Forecast depth | Full: 1X2 + goal markets + correct-score distribution | Most useful for prediction pools |
| Platform | Native iOS (SwiftUI) | User's wheelhouse; accepts App Review timing risk |
| Architecture | Static JSON (Approach C), no database | Supabase free tier exhausted; guarantees 0 € cost |
| Monetization | Free + AdMob | Consistent with user's other iOS apps; max reach in short window |
| Language | English only | International marketability (NA/UK World Cup audience) |
| Name | "World Cup 2026 Odds" | Direct, descriptive App Store name (FIFA-mark risk accepted, see §6.7) |
| Running cost | 0 € guaranteed | Strict free-tier discipline (see §4) |

## 3. Architecture & Data Flow

Three independent, separately testable units:

```
GitHub Actions Cron (every ~6h)
   → fetch odds from The Odds API (region=eu, markets=h2h,totals)
   → compute: devig → 1X2 consensus; Poisson + Dixon-Coles → correct-score grid, O/U, BTTS
   → write predictions.json (all 104 matches)
   → commit to repo
Vercel (Hobby) → serves predictions.json statically over CDN
iOS app (SwiftUI) → loads JSON, caches locally, renders; stores favorite team in UserDefaults; AdMob
```

1. **Data pipeline** (Node script in GitHub Actions): input = bookmaker odds, output = `predictions.json`. The complex math lives here and can be fixed **without an app update**.
2. **Static hosting** (Vercel): dumb layer, serves the JSON.
3. **iOS app** (SwiftUI): loads and displays the JSON; never touches the odds API or any API key.

## 4. Data Pipeline & Compute Model

**Step 1 — Fetch:** `GET /v4/sports/soccer_fifa_world_cup/odds?regions=eu&markets=h2h,totals&oddsFormat=decimal` from The Odds API. Returns multi-bookmaker odds per match.

**Step 2 — Consensus + devig (1X2):**
- Per bookmaker: implied prob `p = 1 / decimal_odds`.
- Remove margin (proportional method): `fair_i = p_i / Σp`.
- Average fair probabilities across all bookmakers → consensus home/draw/away.

**Step 3 — Calibrate goal expectation:** Back out scoring rates `λ_home`, `λ_away` so the model reproduces the market's 1X2 + Over/Under 2.5 line.

**Step 4 — Correct-score distribution:** Poisson grid `P(x,y) = Poisson(x; λ_home)·Poisson(y; λ_away)` for scores 0–5 per team, with **Dixon-Coles correction** (ρ ≈ −0.05 to −0.10) to better fit low scores/draws. Derive: most likely scorelines, Over/Under 2.5, BTTS.

**Step 5 — Emit JSON:** `predictions.json` with all 104 matches. Per match: `id`, `teams {home, away}`, `kickoff` (UTC, ISO 8601), `probs_1x2 {home, draw, away}` (%), `top_scores [{score, pct}]`, `goal_markets {over_under_2_5, btts}`. GitHub Actions commits it; Vercel serves it.

**Honesty note:** This is a market-derived consensus model, not a proprietary prediction edge. Accuracy ≈ the bookmaker market (which is strong). That is exactly the intent.

### Cost discipline (guarantees 0 €)
- The Odds API **free tier** (500 credits/month). Region `eu` only + markets `h2h,totals` = **2 credits/poll**. Every 6h = 120 polls/month × 2 = **240 credits** — comfortably under 500, with headroom for extra match-day polls.
- GitHub Actions: free (public repo unlimited; private 2000 min/month, job uses ~120).
- Vercel Hobby: free static hosting.
- AdMob: free (revenue).
- Apple Developer: already paid.

## 5. iOS App — Screens & UX

SwiftUI, consistent with user's other iOS 26 apps (optional Liquid Glass styling). English UI.

**Screen 1 — Fixtures (home):** List of all 104 matches grouped by date/matchday. Each row: both teams (with flags), kickoff time, compact 1X2 bar (e.g. 52% / 27% / 21%). Filter: All / Today / My Team. Tap → detail. AdMob banner at bottom.

**Screen 2 — Match Detail (core):**
- 1X2 as large labeled bars with percentages.
- Most likely scores: top 3–5 scorelines with % (e.g. 2:1 → 9%, 1:1 → 8%).
- Goal markets: Over/Under 2.5, Both Teams To Score.
- Subtle prediction hint: "Market leans to a narrow home win; most likely score 2:1" — orientation, not a promise.
- Footer: "Based on bookmaker consensus · for entertainment only".
- Optional single interstitial ad on opening detail, sparingly (not every tap).

**Screen 3 — My Team:** Pick favorite team once (stored in UserDefaults, no backend). Shows all of the team's matches across the tournament (group → knockout) with predictions. Optional rough "chance to reach Round of 16/QF" **only if the data supports it**; otherwise omitted (YAGNI).

**Screen 4 — About / Disclaimer:** Data source note, "no real-money gaming, entertainment only", responsible-gambling line + international link.

**Data loading:** On launch, fetch `predictions.json` from Vercel once, cache locally, refresh on reopen. Works offline with last-cached data.

### 5.1 Design quality & direction (must not look "AI slop")

Hard requirement: a premium, native-feeling iOS app. Note this is **native SwiftUI** — web component MCPs (21st.dev, shadcn) target React/web and do **not** apply directly; premium iOS polish comes from Apple HIG + iOS 26 material + the installed design-intelligence skills. During implementation, invoke (in this order):
- **`ui-ux-pro-max`** (SwiftUI stack) — establishes the type scale, color system, spacing, and layout direction up front.
- **`ecc:liquid-glass-design`** — iOS 26 Liquid Glass material for surfaces/cards (the user's signature look, consistent with their other apps).
- **`ecc:make-interfaces-feel-better`** + **`ecc:frontend-design-direction`** — motion, interaction states, microinteractions, polish pass.
- **`banana-claude`** — app icon and visual assets (flag treatment, hero/empty-state art).

Concrete craft bar (the difference between polished and generic):
- Deliberate type scale (SF Pro / SF Rounded), one cohesive accent palette, generous whitespace, consistent corner radii.
- **Custom 1X2 probability bars** — bespoke component, not a default `ProgressView`.
- Proper flag rendering for all 48 nations.
- Real loading / empty / error states (skeletons, not blank screens); subtle data-load motion; haptics on key taps.
- Full dark mode; Dynamic Type support; respects reduced-motion.

Verification: **screenshot every screen on the simulator before calling any UI work done** (user's standing rule — HTTP 200 / "compiles" is not visual verification).

## 6. App Store Compliance (critical path)

Odds-adjacent apps get extra scrutiny. Required to pass review:
1. **17+ age rating** in App Store Connect.
2. **Visible disclaimer:** "This app offers no real-money gaming and accepts no bets. All information is for entertainment and informational purposes only." — on About screen and in the listing.
3. **Responsible-gambling line + link** (international, e.g. begambleaware.org or ncpgambling.org).
4. **No affiliate / bookmaker links in v1** — the single most important rule; links trigger Apple Guideline 5.3.4 (licensing/geo) and German GlüStV. Precedents that ship link-free: BettingPros, Action Network.
5. **No real-money language** anywhere — use "predict", "likelihood", "most likely score", never "bet/wager/stake".
6. **Privacy:** AdMob ⇒ ATT prompt + Privacy Nutrition Labels + privacy policy. Reuse the RateRadar/TitiBina template.
7. **FIFA trademark risk (name):** "World Cup" / "FIFA World Cup" are FIFA trademarks; Apple rejects apps whose names use protected marks or imply official affiliation. The name "World Cup 2026 Odds" uses the protected mark directly, so the rejection risk is real. Mitigations: keep the listing explicitly **unofficial** ("unofficial, not affiliated with FIFA"), avoid FIFA logos/official emblems, and have a fallback name ready (e.g. "WC26 Odds", "Football 2026 Odds") in case of rejection.

**Review-timing strategy (~11 days):** Submit as early as possible with a minimal-but-complete build. Request **Expedited Review** if tight (the World Cup is a valid time-critical justification). If group stage is missed, the knockout stage (from ~July 4) is still a large window.

## 7. Build, Tests & Timeline

### Build setup
- iOS: SwiftUI, local `xcodebuild` + `altool` pipeline (as Noseprint/NetGuard), ASC API key under team `R95M36AU2X`.
- Pipeline: Node script `fetch-and-compute.mjs` + GitHub Actions workflow (cron every 6h) committing `predictions.json`. Vercel serves it.
- Repo layout: `/pipeline` (Node), `/ios` (Xcode project), `/web` (minimal Vercel static host for the JSON).

### Success criteria (verifiable)
1. **Pipeline unit tests:** devig (fair probs sum to 100%), Poisson grid (sums to ≈100%), Dixon-Coles correction applied. Sample odds → expected %.
2. **Schema check:** `predictions.json` validates against a fixed schema (all 104 matches, required fields present).
3. **App loads & renders:** real device/simulator, JSON loads, all 4 screens show plausible values (no empty state) — screenshot-verified, not just "compiles".
4. **Offline fallback:** app shows cached data with no network.
5. **Compliance check:** 17+, disclaimer visible, no betting links, ATT prompt present, listing marked unofficial.

### Timeline (~11 days, indicative)
| Day | Step |
|---|---|
| 1–2 | Pipeline: Odds API + devig/Poisson + JSON, with tests |
| 2–3 | GitHub Actions cron + Vercel hosting live |
| 3–6 | iOS app: 4 screens, JSON loading, AdMob |
| 6–7 | Compliance polish, icon, screenshots, English listing |
| 7 | Submit + request Expedited Review if needed |
| 8–11 | Buffer for review feedback / resubmit |

## 8. Open Risks (acknowledged)

- **Seasonal window:** ~5-week monetization window; treat as a low-cost seasonal experiment, not a venture-scale business.
- **Crowded commodity:** odds→probability is free elsewhere (Forebet, FotMob predictor); differentiation is execution quality, English packaging, and the clean 104-match World Cup focus.
- **FIFA trademark:** name may draw a rejection; mitigated by unofficial framing + fallback name (see §6.7).
- **Review timing:** App Review could miss the group stage; mitigated by early submission + expedited request.
- **Free-tier limits:** if polling needs exceed 500 credits/month, cadence must drop or a one-month $30 tier is needed (would break the 0 € guarantee — avoid by keeping cadence ≤ every 6h, region eu only).
- **Correct-score market thinness:** The Odds API focuses on 1X2 + totals; correct scores are derived via Poisson, not pulled from a market — accuracy depends on the Poisson/Dixon-Coles calibration.
