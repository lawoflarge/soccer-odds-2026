# Design: Full Rebrand to "Soccer Odds 2026" + 5.2.1-Safe Resubmission

**Date:** 2026-06-03
**Status:** Approved for planning
**App:** Apple app id `6775278722`, bundle `com.lawoflarge.worldcup2026odds` (both KEPT)

## Problem

App version 1.0 was rejected on 2026-05-31 under **App Store Review Guideline 5.2.1
(Intellectual Property – General)**. Root cause: the app name and content use **"World
Cup"**, a registered FIFA trademark. FIFA holds trademark registrations for "World Cup",
"FIFA World Cup", "FIFA", the official emblem and the trophy depiction, and enforces them
aggressively during tournament years. The in-app disclaimer ("not affiliated with FIFA")
does **not** cure the infringement — a disclaimer is not a license. This is the standard
FIFA/"World Cup" name rejection; the proven, Apple-sanctioned fix is to remove every
protected mark from all surfaces the reviewer and users can see.

Research sources: theipcenter.com (FIFA World Cup trademarks), Loeb & Loeb (2026 World Cup
unauthorized marketing), FIFA IP Guidelines 2026 (official). Confirmed: descriptive generic
terms ("soccer", "football", a bare year) and factual data (match schedules, national team
names, national flags) are permissible; the protected surface is "World Cup"/"FIFA"/emblem/
trophy.

## Goal & Success Criteria

1. **Zero trademark surface.** `grep -rni "world cup\|fifa"` over the repo and every
   Apple-visible surface (binary strings, App Store listing, screenshots, web pages, public
   domain) returns **no** hits. Exceptions: the kept bundle id string and Apple app id (not
   user/reviewer-visible, not a trademark surface).
2. **New name "Soccer Odds 2026"** appears consistently across home-screen name, listing,
   in-app titles, web, screenshots.
3. **Build still works:** app archives, uploads, runs; 5 unit tests green; live feed loads
   from the new domain; AdMob banner unaffected.
4. **Resubmitted** to App Review with a Resolution Center reviewer note documenting the
   change.

## Decisions (locked)

| Topic | Decision |
|---|---|
| New name | **Soccer Odds 2026** |
| Bundle id / Apple app id | **KEEP** `com.lawoflarge.worldcup2026odds` / `6775278722` (bundle id immutable on existing app; invisible; no trademark value) |
| Internal Xcode target/module/folder | **RENAME** `WorldCup2026Odds` → `SoccerOdds2026` (user's explicit request for full cleanliness) |
| AdMob app/unit ids | **KEEP** (`…~1733904595` / `…/1494761678`) — unaffected by rename |
| Public web | **Full**: scrub page text + move to new domain `soccer-odds-2026.vercel.app` |
| GitHub repo | rename `world-cup-2026-odds` → `soccer-odds-2026` |
| Local folder | rename `~/Data/Claude/world-cup-2026-odds` → `~/Data/Claude/soccer-odds-2026` |
| App icon | KEEP (football + "2026", no trophy/emblem/text mark — not infringing) |

## Replacement Surface (exhaustive)

### A. iOS binary (forces new build + new screenshots)
- `ios/.../Info.plist` + `ios/project.yml` `CFBundleDisplayName`: → "Soccer Odds 2026"
- `FixturesView.swift` `navigationTitle("World Cup 2026")` → "Soccer Odds 2026"
- `AboutView.swift` body: reword without "World Cup"; **remove the word "FIFA" entirely**;
  replace with generic "Independent app. Not affiliated with any football organisation or
  governing body. For entertainment only."
- `Config.swift`: header comment + `feedURL` constant → new domain
- Internal target/module/folder rename `WorldCup2026Odds` → `SoccerOdds2026`: `project.yml`
  target name, source folder `ios/WorldCup2026Odds/` → `ios/SoccerOdds2026/`, test target
  `WorldCup2026OddsTests` → `SoccerOdds2026Tests`, scheme, and regenerate the `.xcodeproj`
  via `xcodegen` (project is xcodegen-managed → safer than hand-editing `pbxproj`).

### B. App Store listing (`scripts/asc_listing.py`, re-run)
- name "Soccer Odds 2026"; subtitle, promo, description, keywords all scrubbed of "world cup"
  and replaced with generic copy (soccer / odds / 2026 / predictions / football / scores)
- marketing/support/privacy URLs → new domain
- Verify ASC accepts the new app name (App Store names must be unique; fall back to a variant
  like "Soccer Odds '26" if taken)

### C. Screenshots (4×) — mandatory regenerate
Rebuild app, run the existing DEBUG launch-arg harness (`-skipATT`, `-tab N`, `-openFirst`),
recapture 6.9" screenshots showing the new "Soccer Odds 2026" header; replace `store/screenshots/*`
and re-upload via `scripts/asc_screenshots.py`.

### D. Web + new domain
- `web/public/index.html`, `support.html`, `privacy.html`: scrub all "World Cup" → "Soccer Odds 2026"
- New Vercel domain `soccer-odds-2026.vercel.app`; predictions feed served at
  `https://soccer-odds-2026.vercel.app/predictions.json` (CORS unchanged)
- `app-ads.txt` content unaffected (AdMob pub id unchanged)
- GitHub Actions cron unchanged (same repo, commits `web/public/predictions.json`)

### E. Repo / infra / docs
- `gh repo rename world-cup-2026-odds soccer-odds-2026` (updates local remote)
- `mv ~/Data/Claude/world-cup-2026-odds ~/Data/Claude/soccer-odds-2026`
- Vercel project rename / new production domain; `.vercel/project.json` follows project id
- `README.md`, `docs/**` cosmetic scrub of "World Cup"
- Update memory note `project_world_cup_2026_odds.md` (repo url, local path, new name, status)

### F. Resubmission
1. Archive + altool upload new build (same key 8XWLD2B2RQ, team R95M36AU2X)
2. Update version 1.0 metadata + screenshots via ASC REST
3. Add **Resolution Center reviewer note** (draft below)
4. Resubmit to App Review.
   - **Known risk:** ASC REST returns **409** when resubmitting a *rejected* version
     (observed on Relatably/Noseprint). Fallback: drive the logged-in Safari via
     `osascript do JavaScript` ("Update / Resubmit to App Review"). This violates the
     default "no Safari automation" preference → **requires explicit per-step authorization
     from Levin before executing.**

### G. Post-approval check
After approval, verify `appAvailabilityV2` is 200 (not 404 "no resource" = removed-from-sale
in 0 territories). If 404, re-add to sale via `POST /v2/appAvailabilities` (all 175
territories) — the known gotcha from NetGuard/PulseCheck.

## Out of Scope
Prediction algorithm, devig/Poisson/Dixon-Coles pipeline, The Odds API integration, AdMob
ids, App Privacy nutrition labels (already set), bundle id, Apple app id. National team
names + flag emojis stay (factual, not FIFA marks).

## Reviewer Note (draft for Resolution Center)
> Thank you for the review. We have fully rebranded this app to "Soccer Odds 2026" and
> removed every reference to the previously-flagged third-party trademark from the app
> binary, the App Store listing (name, subtitle, description, keywords), the screenshots, and
> our website. The app contains only factual sports data — publicly available match
> schedules, national team names, and probabilities derived from aggregated public
> betting-market odds — and uses no third-party emblems, logos, crests, or trophy imagery.
> It is an independent app not affiliated with any football organisation or governing body.

## Risks & Mitigations
| Risk | Mitigation |
|---|---|
| Internal target rename breaks build | xcodegen-managed project → regenerate, not hand-edit pbxproj; run 5 unit tests + archive before submit |
| New domain breaks live feed | update `Config.feedURL` + verify `predictions.json` 200 + CORS from device before submit |
| ASC name "Soccer Odds 2026" taken | check ASC; fallback "Soccer Odds '26" |
| 409 on resubmit of rejected version | Safari `osascript` fallback, with Levin's explicit OK |
| Residual "World Cup" missed somewhere | final `grep -rni "world cup\|fifa"` gate over repo + manual check of rendered listing + screenshots + live web pages |
| Cannot 100%-guarantee Apple | honest framing: full mark removal is the standard fix that clears 5.2.1; this maximises confidence, it is not a literal guarantee |

## Verification Sequence
Each implementation step ends with a check:
1. Rename internal target → `xcodegen generate` + `xcodebuild test` green
2. Scrub binary strings → grep clean in `ios/` + rebuild
3. New domain live → `curl …/predictions.json` 200 + CORS header
4. App loads feed from new domain on simulator → screenshot
5. Regenerate screenshots → visually show "Soccer Odds 2026"
6. Listing updated → fetch back via ASC REST, assert no "world cup"
7. Web pages + repo + folder renamed → grep clean repo-wide
8. Upload build + resubmit → submission state WAITING_FOR_REVIEW
