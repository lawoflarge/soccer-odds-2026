# Soccer Odds 2026 Rebrand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every FIFA "World Cup" trademark surface from the app, its listing, screenshots, website, and repo, rebrand to "Soccer Odds 2026", and resubmit version 1.0 to App Review so it clears guideline 5.2.1.

**Architecture:** Surgical rename across four surfaces — (1) iOS binary (internal Xcode target + user-visible strings), (2) App Store listing metadata + screenshots, (3) public website on a new neutral Vercel domain, (4) GitHub repo + local folder. Bundle id `com.lawoflarge.worldcup2026odds`, Apple app id `6775278722`, and AdMob ids are KEPT (invisible, not a trademark surface). The xcodegen-managed project is regenerated rather than hand-editing `.pbxproj`.

**Tech Stack:** Swift/SwiftUI, xcodegen, xcodebuild, App Store Connect REST API (Python scripts in `scripts/`), Vercel static hosting, GitHub Actions cron, `gh` CLI.

**Working directory (until Task 11):** `~/Data/Claude/world-cup-2026-odds`

**New names (constants used throughout):**
- App display name / App Store name: `Soccer Odds 2026`
- Internal Xcode target/module/folder: `SoccerOdds2026` (was `WorldCup2026Odds`)
- Test target: `SoccerOdds2026Tests`
- New Vercel domain: `soccer-odds-2026.vercel.app`
- New GitHub repo / local folder: `soccer-odds-2026`

---

### Task 0: Pre-flight

**Files:** none (verification only)

- [ ] **Step 1: Confirm clean tree + record the simulator to use**

Run:
```bash
cd ~/Data/Claude/world-cup-2026-odds && git status --porcelain
xcrun simctl list devices available | grep -i iphone | head -5
```
Expected: `git status` prints only the already-committed spec (clean otherwise). Note one available simulator name (e.g. `iPhone 16 Pro`) — substitute it for `<SIM>` in later build commands.

- [ ] **Step 2: Record the full baseline trademark surface (for the final gate)**

Run:
```bash
cd ~/Data/Claude/world-cup-2026-odds && grep -rni "world cup\|fifa" \
  --include="*.swift" --include="*.plist" --include="*.yml" --include="*.html" \
  --include="*.py" --include="*.md" --include="*.json" . | grep -v "docs/superpowers" | sort
```
Expected: a finite list (Config/AboutView/FixturesView/Info.plist/project.yml/web pages/scripts/README). Keep it — every non-`docs/` hit must be gone by Task 12. (Spec docs intentionally keep the words to document the problem.)

---

### Task 1: Rename internal Xcode target/module/folder → SoccerOdds2026

**Files:**
- Rename: `ios/WorldCup2026Odds/` → `ios/SoccerOdds2026/`
- Rename: `ios/WorldCup2026OddsTests/` → `ios/SoccerOdds2026Tests/`
- Modify: `ios/project.yml`
- Regenerate: `ios/*.xcodeproj` (via xcodegen)

- [ ] **Step 1: git mv the source and test folders**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios
git mv WorldCup2026Odds SoccerOdds2026
git mv WorldCup2026OddsTests SoccerOdds2026Tests
```

- [ ] **Step 2: Rewrite `ios/project.yml`**

Replace the whole file with (only names/paths change; bundle ids, team, AdMob id, provisioning specifier UNCHANGED):

```yaml
name: SoccerOdds2026
options:
  bundleIdPrefix: com.lawoflarge
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
packages:
  GoogleMobileAds:
    url: https://github.com/googleads/swift-package-manager-google-mobile-ads.git
    from: "11.0.0"
settings:
  base:
    SWIFT_VERSION: "5.0"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "2"
  configs:
    Debug:
      CODE_SIGNING_ALLOWED: "NO"
targets:
  SoccerOdds2026:
    type: application
    platform: iOS
    sources:
      - path: SoccerOdds2026
    info:
      path: SoccerOdds2026/Info.plist
      properties:
        CFBundleDisplayName: Soccer Odds 2026
        UILaunchScreen: {}
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        GADApplicationIdentifier: ca-app-pub-6563643868702361~1733904595
        NSUserTrackingUsageDescription: "We use your data to show more relevant ads. This keeps the app free."
        ITSAppUsesNonExemptEncryption: false
        SKAdNetworkItems:
          - SKAdNetworkIdentifier: cstr6suwn9.skadnetwork
          - SKAdNetworkIdentifier: 4fzdc2evr5.skadnetwork
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.lawoflarge.worldcup2026odds
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        TARGETED_DEVICE_FAMILY: "1"
      configs:
        Release:
          CODE_SIGNING_ALLOWED: "YES"
          CODE_SIGN_STYLE: Manual
          DEVELOPMENT_TEAM: R95M36AU2X
          CODE_SIGN_IDENTITY: "Apple Distribution"
          PROVISIONING_PROFILE_SPECIFIER: "WorldCup2026Odds ios_app_store 1780260189"
    dependencies:
      - package: GoogleMobileAds
        product: GoogleMobileAds
  SoccerOdds2026Tests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: SoccerOdds2026Tests
      - path: SoccerOdds2026/Resources/sample-predictions.json
        buildPhase: resources
    dependencies:
      - target: SoccerOdds2026
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.lawoflarge.worldcup2026oddsTests
        CODE_SIGNING_ALLOWED: "NO"
```

Notes: `CURRENT_PROJECT_VERSION` bumped `1`→`2` (rejected build 1 number must not be reused). `PROVISIONING_PROFILE_SPECIFIER` stays — the profile is bound to the UNCHANGED bundle id and is a signing artifact never seen by Apple review; it is regenerated with a clean name in Task 8.

- [ ] **Step 3: Regenerate the Xcode project**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && rm -rf WorldCup2026Odds.xcodeproj && xcodegen generate
```
Expected: `Created project at .../ios/SoccerOdds2026.xcodeproj`.

- [ ] **Step 4: Build + run unit tests (regression guard)**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && xcodebuild test \
  -project SoccerOdds2026.xcodeproj -scheme SoccerOdds2026 \
  -destination 'platform=iOS Simulator,name=<SIM>' 2>&1 | tail -25
```
Expected: `** TEST SUCCEEDED **`, 5 tests pass.

- [ ] **Step 5: Commit**

```bash
cd ~/Data/Claude/world-cup-2026-odds && git add -A && \
git commit -m "refactor(ios): rename internal target WorldCup2026Odds -> SoccerOdds2026"
```

---

### Task 2: Scrub user-visible in-app strings

**Files:**
- Modify: `ios/SoccerOdds2026/Views/FixturesView.swift:61`
- Modify: `ios/SoccerOdds2026/Views/AboutView.swift:8,12`
- Modify: `ios/SoccerOdds2026/Config.swift:7` (comment only; URL changes in Task 5)

- [ ] **Step 1: FixturesView navigation title**

In `ios/SoccerOdds2026/Views/FixturesView.swift` change line 61:
```swift
            .navigationTitle("Soccer Odds 2026")
```

- [ ] **Step 2: AboutView — remove "World Cup" and the word "FIFA"**

In `ios/SoccerOdds2026/Views/AboutView.swift`, replace line 8:
```swift
                    Text("Soccer Odds 2026 shows the betting-market consensus for each match of the 2026 tournament, to help you make informed predictions.")
```
and replace line 12:
```swift
                    Text("Independent app. Not affiliated with, endorsed by, or connected to any football organisation or governing body.")
```

- [ ] **Step 3: Config.swift comment**

In `ios/SoccerOdds2026/Config.swift` change line 7:
```swift
    /// AdMob unit IDs — real AdMob IDs (App "Soccer Odds 2026" / Fixtures Banner).
```

- [ ] **Step 4: Verify no trademark strings remain in iOS sources**

```bash
cd ~/Data/Claude/world-cup-2026-odds && grep -rni "world cup\|fifa" ios/SoccerOdds2026 ios/project.yml
```
Expected: **no output**.

- [ ] **Step 5: Rebuild to confirm it still compiles**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && xcodebuild build \
  -project SoccerOdds2026.xcodeproj -scheme SoccerOdds2026 \
  -destination 'platform=iOS Simulator,name=<SIM>' 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
cd ~/Data/Claude/world-cup-2026-odds && git add -A && \
git commit -m "feat(ios): scrub World Cup/FIFA from in-app text -> Soccer Odds 2026"
```

---

### Task 3: Scrub website pages

**Files:**
- Modify: `web/public/index.html`
- Modify: `web/public/support.html`
- Modify: `web/public/privacy.html`

- [ ] **Step 1: Rewrite `web/public/index.html`**

```html
<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Soccer Odds 2026</title>
<style>body{margin:0;font:16px/1.6 -apple-system,system-ui,sans-serif;color:#0f2e1f;background:linear-gradient(160deg,#0e8a4e,#053d24);min-height:100vh;display:flex;align-items:center;justify-content:center;text-align:center}
.c{max-width:640px;padding:40px;color:#fff}h1{font-size:2.4rem;margin:.2em 0}a{color:#9af5c4}</style></head>
<body><div class="c"><h1>⚽ Soccer Odds 2026</h1>
<p>Market-consensus predictions for every match of the 2026 tournament — win/draw/win probabilities, most likely scorelines and goal markets, derived from aggregated bookmaker odds.</p>
<p><strong>Independent app.</strong> Not affiliated with any football organisation or governing body. For entertainment and information only — no betting, no real-money gaming.</p>
<p><a href="/privacy.html">Privacy Policy</a> &nbsp;·&nbsp; <a href="/support.html">Support</a></p></div></body></html>
```

- [ ] **Step 2: Scrub `support.html` and `privacy.html`**

Open each file, replace every "World Cup 2026 Odds" → "Soccer Odds 2026", every standalone "World Cup" → "tournament" (or "Soccer Odds 2026" where it is the product name), and remove any "FIFA" mention. Keep all other content (privacy text, contact email) intact.

- [ ] **Step 3: Verify web pages are clean**

```bash
cd ~/Data/Claude/world-cup-2026-odds && grep -rni "world cup\|fifa" web/
```
Expected: **no output**.

- [ ] **Step 4: Commit**

```bash
cd ~/Data/Claude/world-cup-2026-odds && git add -A && \
git commit -m "feat(web): rebrand landing/support/privacy to Soccer Odds 2026"
```

---

### Task 4: New Vercel domain `soccer-odds-2026.vercel.app`

**Files:**
- Modify: `.vercel/project.json` (projectName field)

> This task touches Vercel's hosted project. It is the one step that may need the dashboard. Do NOT rename the GitHub repo here (that is Task 11) — only the Vercel project/domain.

- [ ] **Step 1: Rename the Vercel project to get the new production domain**

In the Vercel dashboard: project `world-cup-2026-odds` → Settings → General → **Project Name** → `soccer-odds-2026` → Save. This makes `soccer-odds-2026.vercel.app` the production domain. (The git connection is by repo id and is preserved.)

If Levin prefers CLI, he can run in the session with `! vercel link` then rename via dashboard — Vercel has no stable project-rename CLI verb.

- [ ] **Step 2: Trigger/await a production deploy and verify the feed on the new domain**

```bash
curl -sS -D - -o /dev/null https://soccer-odds-2026.vercel.app/predictions.json | head -20
```
Expected: `HTTP/2 200` and an `access-control-allow-origin: *` header. (If 404, the deploy has not propagated — wait and retry, or push an empty commit to trigger redeploy.)

- [ ] **Step 3: Update the local Vercel project name marker + commit**

In `.vercel/project.json` set `"projectName":"soccer-odds-2026"` (leave `projectId`/`orgId` untouched).
```bash
cd ~/Data/Claude/world-cup-2026-odds && git add .vercel/project.json && \
git commit -m "chore(vercel): project renamed to soccer-odds-2026"
```

---

### Task 5: Point the app at the new feed domain

**Files:**
- Modify: `ios/SoccerOdds2026/Config.swift:5`

- [ ] **Step 1: Update the feed URL**

In `ios/SoccerOdds2026/Config.swift` change line 5:
```swift
    static let predictionsURL = URL(string: "https://soccer-odds-2026.vercel.app/predictions.json")!
```

- [ ] **Step 2: Verify the app loads the feed from the new domain (simulator)**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && xcodebuild build \
  -project SoccerOdds2026.xcodeproj -scheme SoccerOdds2026 \
  -destination 'platform=iOS Simulator,name=<SIM>' 2>&1 | tail -3
xcrun simctl boot "<SIM>" 2>/dev/null; sleep 3
# install + launch the built .app, then screenshot the Fixtures screen
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "SoccerOdds2026.app" -path "*Debug-iphonesimulator*" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.lawoflarge.worldcup2026odds -skipATT -tab 0 -openFirst
sleep 4 && xcrun simctl io booted screenshot /tmp/feed-check.png
```
Expected: `/tmp/feed-check.png` shows the Fixtures list populated with matches (proves the new-domain feed loaded) and the header reads "Soccer Odds 2026". **View the screenshot to confirm** (do not assume).

- [ ] **Step 3: Commit**

```bash
cd ~/Data/Claude/world-cup-2026-odds && git add -A && \
git commit -m "feat(ios): point feed at soccer-odds-2026.vercel.app"
```

---

### Task 6: Regenerate the 4 App Store screenshots

**Files:**
- Replace: `store/screenshots/01-fixtures.png`, `02-detail.png`, `03-myteam.png`, `04-about.png`

- [ ] **Step 1: Capture all four screens from the rebuilt app**

With the simulator booted and the app installed (Task 5), capture each tab via the DEBUG launch-arg harness (a 6.9"/iPhone 16 Pro Max-class device is required for the `APP_IPHONE_67` display type; boot the right sim if needed):

```bash
SIM="<6.9-inch SIM, e.g. iPhone 16 Pro Max>"
xcrun simctl boot "$SIM" 2>/dev/null; sleep 3
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "SoccerOdds2026.app" -path "*Debug-iphonesimulator*" | head -1)
xcrun simctl install "$SIM" "$APP"
cap(){ xcrun simctl launch "$SIM" com.lawoflarge.worldcup2026odds "$@"; sleep 5; }
cap -skipATT -tab 0 -openFirst;  xcrun simctl io "$SIM" screenshot store/screenshots/01-fixtures.png
cap -skipATT -tab 0 -openFirst;  xcrun simctl io "$SIM" screenshot store/screenshots/02-detail.png   # tap into a match if the harness needs it
cap -skipATT -tab 1;             xcrun simctl io "$SIM" screenshot store/screenshots/03-myteam.png
cap -skipATT -tab 2;             xcrun simctl io "$SIM" screenshot store/screenshots/04-about.png
```
(Adjust the per-screen launch args to match the harness flags actually present in `App.swift`/`RootView.swift`.)

- [ ] **Step 2: Verify each screenshot visually**

View all four PNGs. Confirm: the Fixtures header says "Soccer Odds 2026" (NOT "World Cup 2026"), the About screen shows the new independent-app disclaimer with no "FIFA", and resolution is 1290×2796 (6.9").

- [ ] **Step 3: Commit**

```bash
cd ~/Data/Claude/world-cup-2026-odds && git add store/screenshots && \
git commit -m "feat(store): regenerate screenshots with Soccer Odds 2026 branding"
```

---

### Task 7: Rewrite App Store listing metadata script

**Files:**
- Modify: `scripts/asc_listing.py`

- [ ] **Step 1: Replace the constants + add the app NAME to the appInfoLocalizations PATCH**

In `scripts/asc_listing.py` set the metadata constants:
```python
NAME="Soccer Odds 2026"
SUBTITLE="Match predictions & odds"
PROMO="Free predictions for every match of the 2026 tournament - win/draw probabilities, most likely scores and goal markets, from the betting-market consensus."
KEYWORDS="soccer,odds,2026,prediction,football,score,tournament,tips,fixtures,probability,bracket,kicktipp"
MARKETING_URL="https://soccer-odds-2026.vercel.app"
PRIVACY_URL="https://soccer-odds-2026.vercel.app/privacy.html"
SUPPORT_URL="https://soccer-odds-2026.vercel.app/support.html"
DESCRIPTION="""The smart way to predict the 2026 tournament.

Soccer Odds 2026 shows you the betting-market consensus for every match - so you can make sharper predictions in your office pool, with friends, or just to follow your favourite team.

WHAT YOU GET

- Win / draw / win probabilities for all matches, derived from aggregated bookmaker odds
- The most likely scoreline for each match, right on the home screen
- Goal markets: over/under 2.5 goals and both-teams-to-score
- Pick your favourite team and follow its predicted path
- Clean, fast, and free

HOW IT WORKS

For every match we aggregate the odds from multiple bookmakers, remove the bookmaker margin, and turn them into fair probabilities and a statistical goal model. The result is the market consensus - what the betting market, in aggregate, expects to happen.

INDEPENDENT & FOR ENTERTAINMENT

Soccer Odds 2026 is an independent app. It is not affiliated with, endorsed by, or connected to any football organisation or governing body. It offers no real-money gaming and accepts no bets - all information is for entertainment and informational purposes only. Predictions reflect the market and are not guaranteed.

CONTACT
Email: levin.schwab@gmx.de
Privacy: https://soccer-odds-2026.vercel.app/privacy.html
"""
```

Then update the appInfoLocalizations PATCH (the line that currently sets only `subtitle` + `privacyPolicyUrl`) to ALSO set the name:
```python
api("PATCH",f"/v1/appInfoLocalizations/{en['id']}",{"data":{"type":"appInfoLocalizations","id":en["id"],"attributes":{"name":NAME,"subtitle":SUBTITLE,"privacyPolicyUrl":PRIVACY_URL}}})
```
(The `appStoreVersionLocalizations` PATCH already sends DESCRIPTION/KEYWORDS/PROMO/URLs — no structural change beyond the new constant values.)

- [ ] **Step 2: Verify the script has no trademark strings**

```bash
cd ~/Data/Claude/world-cup-2026-odds && grep -ni "world cup\|fifa" scripts/asc_listing.py
```
Expected: **no output**.

- [ ] **Step 3: Commit**

```bash
cd ~/Data/Claude/world-cup-2026-odds && git add scripts/asc_listing.py && \
git commit -m "feat(store): rebrand listing metadata to Soccer Odds 2026"
```

---

### Task 8: Re-provision signing with a clean profile name

**Files:**
- Modify: `scripts/asc_provision.py:7,58`
- Modify: `ios/project.yml` (PROVISIONING_PROFILE_SPECIFIER)

> Bundle id is UNCHANGED, so the old profile would still work. We regenerate only to drop "WorldCup2026Odds" from the (invisible) profile name, per the full-rename request.

- [ ] **Step 1: Rename the profile prefix in the script**

In `scripts/asc_provision.py`: set `BUNDLE_NAME="SoccerOdds2026"` (line 7) and change the profile name on line 58 to:
```python
name=f"SoccerOdds2026 ios_app_store {TS}"
```

- [ ] **Step 2: Run it and capture the new profile name**

```bash
cd ~/Data/Claude/world-cup-2026-odds && python3 scripts/asc_provision.py
```
Expected output ends with `PROFILE_NAME=SoccerOdds2026 ios_app_store <timestamp>` and `installed -> .../<uuid>.mobileprovision`.

- [ ] **Step 3: Put that exact profile name into `ios/project.yml`**

Set the Release `PROVISIONING_PROFILE_SPECIFIER` to the captured `SoccerOdds2026 ios_app_store <timestamp>`, then regenerate:
```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && xcodegen generate
```

- [ ] **Step 4: Commit**

```bash
cd ~/Data/Claude/world-cup-2026-odds && git add -A && \
git commit -m "chore(signing): regenerate App Store profile under SoccerOdds2026 name"
```

---

### Task 9: Archive, export, upload the new build

**Files:**
- Uses: `scripts/ExportOptions.plist`
- Produces: `ios/build/SoccerOdds2026.xcarchive`, `ios/build/export/*.ipa`

- [ ] **Step 1: Archive (Release, signed)**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && xcodebuild \
  -project SoccerOdds2026.xcodeproj -scheme SoccerOdds2026 -configuration Release \
  -archivePath build/SoccerOdds2026.xcarchive archive 2>&1 | tail -5
```
Expected: `** ARCHIVE SUCCEEDED **`.

- [ ] **Step 2: Export the IPA**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && xcodebuild -exportArchive \
  -archivePath build/SoccerOdds2026.xcarchive \
  -exportOptionsPlist ../scripts/ExportOptions.plist \
  -exportPath build/export 2>&1 | tail -5
```
Expected: an `.ipa` in `build/export/`. (If `ExportOptions.plist` pins the old profile name, update it to the Task 8 profile name first.)

- [ ] **Step 3: Upload to App Store Connect**

```bash
cd ~/Data/Claude/world-cup-2026-odds/ios && xcrun altool --upload-app -t ios \
  -f build/export/*.ipa \
  --apiKey 8XWLD2B2RQ --apiIssuer 538cb0d4-b8c6-4bc7-8b59-75da5d2b9411 2>&1 | tail -5
```
Expected: `No errors uploading`. Build 1.0 (2) appears in ASC "Processing" within ~10 min.

- [ ] **Step 4: Verify the build registered**

Wait ~10 min, then confirm in ASC (or via REST `GET /v1/apps/6775278722/builds`) that build `2` for version 1.0 is available to attach. Expected: build 2 present, processing complete.

---

### Task 10: Push listing metadata + screenshots, attach build

**Files:** none new (runs Task 7 + Task 6 outputs)

- [ ] **Step 1: Push the rebranded listing**

```bash
cd ~/Data/Claude/world-cup-2026-odds && python3 scripts/asc_listing.py
```
Expected: prints `subtitle + privacy url set` and `desc=… keywords=… set`, no HTTP error. **If the PATCH fails with a name-taken / "name is already in use" error**, the App Store name "Soccer Odds 2026" is unavailable — set `NAME="Soccer Odds '26"` in `scripts/asc_listing.py` and re-run (the in-binary `CFBundleDisplayName` may stay "Soccer Odds 2026"; only the unique App Store listing name needs to differ).

- [ ] **Step 2: Verify the live listing has no trademark via REST**

Fetch the app's `appInfoLocalizations` + `appStoreVersionLocalizations` back (reuse the `jwtok`/`api` helpers in `asc_listing.py`) and assert none of `name`, `subtitle`, `description`, `keywords` contains "world cup"/"fifa" (case-insensitive). Expected: assertion passes.

- [ ] **Step 3: Upload the new screenshots**

```bash
cd ~/Data/Claude/world-cup-2026-odds && python3 scripts/asc_screenshots.py
```
Expected: `uploaded 01-fixtures.png` … `DONE 4 screenshots`.

- [ ] **Step 4: Attach build 2 to version 1.0**

Via ASC REST: PATCH the appStoreVersion's `build` relationship to the build whose `version == "2"`. Expected: the version page shows build 2 attached.

---

### Task 11: Rename GitHub repo + local folder

> Done late so earlier build/upload commands keep a stable path. After this, the working directory is `~/Data/Claude/soccer-odds-2026`.

**Files:** none (infra) + README/docs scrub

- [ ] **Step 1: Rename the GitHub repo (updates the local remote automatically)**

```bash
cd ~/Data/Claude/world-cup-2026-odds && gh repo rename soccer-odds-2026 --yes
git remote -v
```
Expected: remote now `https://github.com/lawoflarge/soccer-odds-2026.git`.

- [ ] **Step 2: Rename the local folder**

```bash
cd ~/Data/Claude && mv world-cup-2026-odds soccer-odds-2026 && cd soccer-odds-2026 && pwd
```
Expected: `/Users/levinschwab/Data/Claude/soccer-odds-2026`.

- [ ] **Step 3: Scrub README (cosmetic)**

In `README.md` replace product references "World Cup 2026 Odds" → "Soccer Odds 2026" and standalone "World Cup" → "tournament". The dated `docs/superpowers/{specs,plans}/2026-05-31-*.md` files may keep their historical wording, but the README (public on the renamed repo) must be clean.

- [ ] **Step 4: Commit + push everything**

```bash
cd ~/Data/Claude/soccer-odds-2026 && git add -A && \
git commit -m "chore: rebrand repo + README to Soccer Odds 2026" && git push
```
Expected: push succeeds to the renamed repo; Vercel auto-deploys.

---

### Task 12: Final trademark gate + resubmit

**Files:** none

- [ ] **Step 1: Repo-wide final gate**

```bash
cd ~/Data/Claude/soccer-odds-2026 && grep -rni "world cup\|fifa" \
  --include="*.swift" --include="*.plist" --include="*.yml" --include="*.html" \
  --include="*.py" --include="*.md" --include="*.json" . | grep -v "docs/superpowers/specs/2026-06-03"
```
Expected: **no output** except, intentionally, the 2026-06-03 spec (which documents the problem). The older dated 2026-05-31 plan/spec files are acceptable historical record; every other surface must be clean.

- [ ] **Step 2: Manually verify the rendered surfaces**

- Open `https://soccer-odds-2026.vercel.app` and `/support.html` and `/privacy.html` — no "World Cup"/"FIFA".
- In ASC, confirm name = "Soccer Odds 2026", screenshots show the new header, description/keywords clean.

- [ ] **Step 3: Add the Resolution Center reviewer note**

Reply to the open submission in App Store Connect → Resolution Center with:
> Thank you for the review. We have fully rebranded this app to "Soccer Odds 2026" and removed every reference to the previously-flagged third-party trademark from the app binary, the App Store listing (name, subtitle, description, keywords), the screenshots, and our website. The app contains only factual sports data — publicly available match schedules, national team names, and probabilities derived from aggregated public betting-market odds — and uses no third-party emblems, logos, crests, or trophy imagery. It is an independent app not affiliated with any football organisation or governing body.

- [ ] **Step 4: Resubmit to App Review**

Attempt via ASC REST: create a `reviewSubmission`, add the version as an item, submit.
- **If REST returns 409** (known for a rejected version): STOP and ask Levin for explicit authorization to use the Safari `osascript do JavaScript` fallback (`scripts/safari_js.py`) to click "Resubmit to App Review" in the logged-in browser — this overrides the default no-Safari-automation rule and needs his per-step OK.

Expected: version 1.0 state → `WAITING_FOR_REVIEW`.

- [ ] **Step 5: Update the memory note**

Update `~/.claude/projects/-Users-levinschwab/memory/project_world_cup_2026_odds.md` and `MEMORY.md`: new repo url `github.com/lawoflarge/soccer-odds-2026`, local path `~/Data/Claude/soccer-odds-2026`, new name "Soccer Odds 2026", new domain, and status (5.2.1 rejection fixed, build 2 resubmitted).

---

### Post-approval (separate, after Apple approves)

- [ ] Verify `appAvailabilityV2` returns 200 (not 404 "no resource" = removed-from-sale in 0 territories). If 404, re-add to sale via `POST /v2/appAvailabilities` for all 175 territories (the NetGuard/PulseCheck gotcha).
