// Soccer Odds 2026 App Store "Glow-Up" — Stage A: native screen capture.
//
// Builds the real SwiftUI app (Debug — the screenshot harness is #if DEBUG) for
// an iPhone 16 Pro Max simulator, then relaunches it per screen with the built-in
// harness launch arguments to grab clean, device-less app screens at native
// 1320x2868 into ./screens:
//
//   -screenshotData  load bundled deterministic demo data (sample-*.json)
//   -proUnlocked     unlock Pro  ⇒  no ad banner + Pro features visible
//   -tab N           jump to a tab (0 Fixtures · 1 Tournament · 2 My Team · 3 More)
//   -openFirst       on Fixtures, push the first match's detail view
//
// Direct tab launching makes capture far more deterministic than UI driving.
// My Team needs a pinned team, so we AXe-tap one in the picker.
//
//   node capture.mjs --app soccer-odds
//
// These captures are committed, so build.mjs SKIPS this stage by default.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const IOS_DIR = path.resolve(__dirname, "..", "..", "ios");
const SCREENS = path.join(__dirname, "screens");

const BUNDLE = "com.lawoflarge.worldcup2026odds";
const SIM_NAME = "SO-Shots-69";
const SIM_DEVICE = "iPhone 16 Pro Max";
const SCHEME = "SoccerOdds2026";
const PROJECT = "SoccerOdds2026.xcodeproj";
const DD = "/tmp/so_dd";

const sh = (cmd, a, opts = {}) =>
  execFileSync(cmd, a, { stdio: ["ignore", "pipe", "pipe"], encoding: "utf8", ...opts });
const sleep = (s) => { try { execFileSync("sleep", [String(s)]); } catch {} };
const log = (m) => console.log(m);

function ensureSim() {
  const list = sh("xcrun", ["simctl", "list", "devices"]);
  let udid = new RegExp(`${SIM_NAME} \\(([0-9A-F-]+)\\)`).exec(list)?.[1];
  if (!udid) {
    const rt = /com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+/.exec(
      sh("xcrun", ["simctl", "list", "runtimes"]),
    )?.[0];
    udid = sh("xcrun", ["simctl", "create", SIM_NAME, SIM_DEVICE, rt]).trim();
    log(`  created sim ${udid}`);
  }
  try { sh("xcrun", ["simctl", "boot", udid]); } catch {}
  return udid;
}

function buildAndInstall(udid) {
  log("  xcodegen + xcodebuild (Debug, simulator)…");
  sh("xcodegen", ["generate"], { cwd: IOS_DIR });
  execFileSync("xcodebuild", [
    "-project", PROJECT, "-scheme", SCHEME,
    "-configuration", "Debug", "-sdk", "iphonesimulator",
    "-destination", `id=${udid}`, "-derivedDataPath", DD, "-quiet", "build",
  ], { cwd: IOS_DIR, stdio: "inherit" });
  const app = `${DD}/Build/Products/Debug-iphonesimulator/${SCHEME}.app`;
  try { sh("xcrun", ["simctl", "uninstall", udid, BUNDLE]); } catch {}
  sh("xcrun", ["simctl", "install", udid, app]);
  // Force Dark Mode: FixturesView uses system colors, so it only renders the dark
  // "Stadion Premium" theme (consistent with the other screens) in dark appearance.
  try { sh("xcrun", ["simctl", "ui", udid, "appearance", "dark"]); } catch {}
  sh("xcrun", ["simctl", "status_bar", udid, "override", "--time", "9:41",
    "--dataNetwork", "wifi", "--wifiBars", "3", "--cellularMode", "active",
    "--cellularBars", "4", "--batteryState", "discharging", "--batteryLevel", "100"]);
}

const BASE = ["-screenshotData", "-proUnlocked"];
function launch(udid, extra = []) {
  try { sh("xcrun", ["simctl", "terminate", udid, BUNDLE]); } catch {}
  sh("xcrun", ["simctl", "launch", udid, BUNDLE, ...BASE, ...extra]);
  sleep(3);
}
const axe = (a, udid) => { try { return sh("axe", [...a, "--udid", udid]); } catch (e) { return ""; } };
const tap = (label, udid, post = 1.6) => axe(["tap", "--label", label, "--post-delay", String(post)], udid);
const swipe = (sy, ey, udid) =>
  axe(["swipe", "--start-x", "220", "--start-y", String(sy), "--end-x", "220", "--end-y", String(ey), "--duration", "0.4"], udid);
const shot = (id, udid) => {
  sh("xcrun", ["simctl", "io", udid, "screenshot", "--type", "png", path.join(SCREENS, `${id}.png`)]);
  log(`  ✓ ${id}.png`);
};

function captureAll(udid) {
  // 01 Fixtures — daily consensus odds list (Pro ⇒ edge badges in rows, no banner)
  launch(udid, ["-tab", "0"]); shot("01-fixtures", udid);

  // 02 Match detail — 1X2 + most-likely scores + O/U + BTTS
  launch(udid, ["-tab", "0", "-openFirst"]); shot("02-detail", udid);

  // 03 Tournament — Monte-Carlo title odds (top of ranked list)
  launch(udid, ["-tab", "1"]); shot("03-tournament", udid);

  // 05 My Team — pin a strong side in the picker, then capture the team view
  launch(udid, ["-tab", "2"]);
  tap("Brazil", udid, 2.0);
  shot("05-myteam", udid);
}

fs.mkdirSync(SCREENS, { recursive: true });
const udid = ensureSim();
buildAndInstall(udid);
log("  capturing…");
captureAll(udid);
log(`\n✅ Captured native screens → ${SCREENS}`);
console.log("   Verify the PNGs visually before compositing.");
