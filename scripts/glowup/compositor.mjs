// Soccer Odds 2026 App Store "Glow-Up" compositor.
//
// Stage B. Composites the REAL native dark app UI — embedded in a real iPhone 16
// Pro Max Black-Titanium frame (Koubou, via frame-device.py) — onto a BRIGHT
// stadium-grass poster at EXACTLY 1290x2796 (ASC 6.9" `_67`), using Playwright/
// Chromium as an HTML renderer. Fully offline: the grass photo, framed device,
// fonts and the real app icon are base64-embedded; no network at render time.
//
// Brand-consistent with the app: gold (#FFD24A) accent word + green (#3AD17F)
// inside dark callout cards + the real grass-stadium app icon. The dark phone
// "floats" on vibrant grass; a top scrim keeps the gold/white text legible.
// In-device pixels are untouched native captures; callouts are 1:1 crops.
//
// Usage: node compositor.mjs [--app soccer-odds] [--frames 01-fixtures,...] [--dpr 2] [--ipad]
// Output: ./out/<id>.png  (exactly 1290x2796, or 2064x2752 with --ipad)

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const PLAYWRIGHT_PATH =
  process.env.PLAYWRIGHT_PATH ??
  "/Users/levinschwab/Data/Claude/browser-automation/node_modules/playwright/index.mjs";
const { chromium } = await import(PLAYWRIGHT_PATH);

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCREENS = path.join(__dirname, "screens");
const FONTS = path.join(__dirname, "fonts");
const ASSETS = path.join(__dirname, "assets");
const OUT = path.join(__dirname, "out");
const FRAMED = path.join(OUT, ".framed");
const ICON = path.join(ASSETS, "icon.png");

const args = process.argv.slice(2);
const argVal = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : dflt;
};
const APP = argVal("app", "soccer-odds");
const DPR = Number(argVal("dpr", "2"));
const frameFilter = argVal("frames", null);
const IPAD = args.includes("--ipad");

const config = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"))[APP];
if (!config) throw new Error(`No config for app "${APP}"`);
const P = config.palette;
const W = IPAD ? 2064 : config.size.w;   // iPad Pro 12.9" 2064x2752 (APP_IPAD_PRO_3GEN_129)
const H = IPAD ? 2752 : config.size.h;   // iPhone 6.9" 1290x2796 (APP_IPHONE_67)
const GOLD = P.gold, GREEN = P.green;

const b64 = (p) => fs.readFileSync(p).toString("base64");
const FONT_GROTESK = b64(path.join(FONTS, "SpaceGrotesk.ttf"));
const FONT_MONO = b64(path.join(FONTS, "JetBrainsMono.ttf"));
const ICON_URI = `data:image/png;base64,${b64(ICON)}`;
const GRASS_DAY = `data:image/jpeg;base64,${b64(path.join(__dirname, config.grassImage))}`;
const GRASS_NIGHT = `data:image/jpeg;base64,${b64(path.join(__dirname, config.grassNight))}`;
const screenUri = (file) => `data:image/png;base64,${b64(path.join(SCREENS, file))}`;

const SCREEN_W = 1320, SCREEN_H = 2868;

// ── framed device generation (real iPhone Black-Titanium frame) ───────────────
function ensureFramed(screenFile) {
  fs.mkdirSync(FRAMED, { recursive: true });
  const out = path.join(FRAMED, screenFile);
  if (!fs.existsSync(out) || fs.statSync(out).mtimeMs < fs.statSync(path.join(SCREENS, screenFile)).mtimeMs) {
    execFileSync("python3", [path.join(__dirname, "frame-device.py"), path.join(SCREENS, screenFile), out], { stdio: "ignore" });
  }
  return `data:image/png;base64,${b64(out)}`;
}

function headlineHTML(text, accent) {
  if (accent && text.includes(accent)) {
    const [a, b] = text.split(accent);
    return `${a}<span class="accent">${accent}</span>${b}`;
  }
  return text;
}

function deviceImg(screenFile, klass) {
  return `<div class="dev-wrap ${klass}"><div class="contact"></div><img class="device-img" src="${ensureFramed(screenFile)}" alt=""/></div>`;
}

function calloutCard(screenFile, cropFrac, cardW, caption) {
  const [fx, fy, fw, fh] = cropFrac;
  const scale = cardW / (fw * SCREEN_W);
  const imgW = SCREEN_W * scale, imgH = SCREEN_H * scale;
  const tx = -fx * SCREEN_W * scale, ty = -fy * SCREEN_H * scale;
  const clipH = Math.round(fh * SCREEN_H * scale);
  return `<div class="callout-card" style="width:${cardW}px;">
    <div class="callout-clip" style="height:${clipH}px;">
      <img src="${screenUri(screenFile)}" style="width:${imgW}px; height:${imgH}px; transform:translate(${tx}px, ${ty}px);"/>
    </div>
    ${caption ? `<div class="callout-cap"><span class="dot"></span>${caption}</div>` : ""}
  </div>`;
}

function header(f) {
  return `<header class="head">
    <div class="eyebrow">${f.eyebrow}</div>
    <h1 class="headline">${headlineHTML(f.headline, f.accent)}</h1>
    <p class="subline">${f.subline}</p>
  </header>`;
}
function footer() {
  return `<footer class="foot">
    <img class="foot-icon" src="${ICON_URI}"/>
    <span class="wordmark">${config.wordmark}</span>
  </footer>`;
}

const LAYOUTS = {
  hero(f) {
    return `${header(f)}${deviceImg(f.screen, "dev-hero")}${footer()}`;
  },
  callout(f) {
    const card = f.callout
      ? `<div class="callout-wrap"><div class="leader"></div>${calloutCard(f.screen, f.callout.cropFrac, 660, f.callout.caption)}</div>`
      : "";
    return `${header(f)}${deviceImg(f.screen, "dev-callout")}${card}${footer()}`;
  },
  cta(f) {
    return `${header(f)}${f.cta ? `<div class="cta-btn">${f.cta}</div>` : ""}${deviceImg(f.screen, "dev-cta")}${footer()}`;
  },
};

function css(grass) {
  const dayScrim = "linear-gradient(180deg, rgba(7,11,9,0.80) 0%, rgba(7,11,9,0.52) 16%, rgba(7,11,9,0.0) 38%, rgba(7,11,9,0.0) 70%, rgba(7,11,9,0.55) 100%)";
  const nightScrim = "linear-gradient(180deg, rgba(7,11,9,0.74) 0%, rgba(7,11,9,0.40) 22%, rgba(7,11,9,0.20) 50%, rgba(7,11,9,0.62) 100%)";
  const scrim = grass === "night" ? nightScrim : dayScrim;
  const grassUri = grass === "night" ? GRASS_NIGHT : GRASS_DAY;
  const grassFilter = grass === "night" ? "saturate(1.12) brightness(1.16)" : "saturate(1.28) brightness(1.3)";
  const bloom = grass === "night"
    ? "radial-gradient(60% 32% at 50% 6%, rgba(255,255,255,0.18), rgba(255,255,255,0) 60%)"
    : "radial-gradient(70% 40% at 50% 0%, rgba(255,255,255,0.16), rgba(255,255,255,0) 55%)";
  return `
  @font-face { font-family:'Grotesk'; src:url(data:font/ttf;base64,${FONT_GROTESK}) format('truetype'); font-weight:300 800; }
  @font-face { font-family:'Mono'; src:url(data:font/ttf;base64,${FONT_MONO}) format('truetype'); font-weight:300 800; }
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:${W}px; height:${H}px; }
  body { position:relative; overflow:hidden; background:${P.depthBase}; font-family:'Grotesk',sans-serif; -webkit-font-smoothing:antialiased; }

  .grass { position:absolute; inset:0; background-image:url(${grassUri}); background-size:cover; background-position:center 62%; filter:${grassFilter}; }
  .grass.blur-far::after { content:''; position:absolute; inset:0 0 58% 0; backdrop-filter:blur(3px); -webkit-backdrop-filter:blur(3px); }
  .bloom { position:absolute; inset:0; background:${bloom}; mix-blend-mode:screen; }
  .scrim { position:absolute; inset:0; background:${scrim}; }
  .text-scrim { position:absolute; top:0; left:0; right:0; height:40%; z-index:1; background:linear-gradient(180deg, rgba(13,18,24,0.90) 0%, rgba(13,18,24,0.6) 38%, rgba(13,18,24,0) 100%); }
  .vignette { position:absolute; inset:0; box-shadow: inset 0 0 460px 120px rgba(0,0,0,0.5); pointer-events:none; }
  .stage { position:absolute; inset:0; z-index:2; }

  .head { position:absolute; top:122px; left:96px; right:96px; z-index:5; }
  .eyebrow { font-family:'Mono'; font-weight:700; font-size:33px; letter-spacing:0.16em; color:#EAF1E6; text-transform:uppercase; margin-bottom:22px; text-shadow:0 2px 14px rgba(0,0,0,0.85); }
  .headline { font-family:'Grotesk'; font-weight:700; font-size:92px; line-height:1.02; letter-spacing:-0.026em; color:#FFFFFF; text-wrap:balance; max-width:1050px; text-shadow:0 4px 22px rgba(0,0,0,0.62), 0 1px 3px rgba(0,0,0,0.5); }
  .headline .accent { color:${GOLD}; }
  .subline { margin-top:26px; font-family:'Grotesk'; font-weight:600; font-size:37px; line-height:1.3; color:#E8EEE6; max-width:960px; text-shadow:0 2px 18px rgba(0,0,0,0.9), 0 1px 3px rgba(0,0,0,0.6); }

  .dev-wrap { position:absolute; left:50%; transform:translateX(-50%); z-index:3; }
  .device-img { width:100%; display:block; position:relative; z-index:3;
      filter: drop-shadow(0 64px 80px rgba(0,0,0,0.62)) drop-shadow(0 8px 24px rgba(0,0,0,0.5)); }
  .contact { position:absolute; left:50%; bottom:-26px; transform:translateX(-50%); width:78%; height:120px; z-index:2;
      background:radial-gradient(50% 50% at 50% 50%, rgba(0,0,0,0.6), rgba(0,0,0,0) 72%); filter:blur(8px); }
  .dev-hero { width:1004px; top:566px; }
  .dev-callout { width:1004px; top:566px; }
  .dev-cta { width:900px; top:700px; }
  .dev-cta .device-img { filter: drop-shadow(0 64px 80px rgba(0,0,0,0.62)) drop-shadow(0 0 66px rgba(255,210,74,0.32)); }

  .callout-wrap { position:absolute; right:40px; top:2090px; z-index:8; }
  .callout-card { position:relative; border-radius:30px; overflow:hidden; background:${P.depthSurface};
      box-shadow: 0 40px 80px -18px rgba(0,0,0,0.75), 0 0 0 1.5px rgba(255,210,74,0.65), 0 0 56px 0 rgba(255,210,74,0.22); }
  .callout-clip { position:relative; overflow:hidden; width:100%; }
  .callout-clip img { position:absolute; left:0; top:0; max-width:none; }
  .callout-cap { display:flex; align-items:center; gap:12px; padding:16px 24px 18px; font-family:'Mono'; font-weight:700;
      font-size:24px; letter-spacing:0.12em; text-transform:uppercase; color:#FFDD8C; background:rgba(7,11,9,0.62); border-top:1px solid rgba(255,210,74,0.4); }
  .callout-cap .dot { width:13px; height:13px; border-radius:50%; background:${GOLD}; box-shadow:0 0 10px ${GOLD}; }
  .leader { position:absolute; left:-120px; top:80px; width:142px; height:2px; background:linear-gradient(90deg, rgba(255,210,74,0), ${GOLD}); z-index:7; box-shadow:0 0 8px rgba(255,210,74,0.5); }
  .leader::before { content:''; position:absolute; left:-7px; top:-4px; width:10px; height:10px; border-radius:50%; background:${GOLD}; box-shadow:0 0 10px ${GOLD}; }

  .cta-btn { position:absolute; top:536px; left:96px; z-index:6; padding:28px 54px; border-radius:999px;
      background:${GOLD}; color:#241400; font-family:'Grotesk'; font-weight:700; font-size:36px;
      box-shadow:0 26px 60px -16px rgba(255,210,74,0.6), 0 0 0 1px rgba(255,255,255,0.2); white-space:nowrap; }

  .foot { position:absolute; left:96px; bottom:74px; z-index:10; display:flex; align-items:center; gap:18px;
      padding:14px 26px 14px 14px; border-radius:999px; background:rgba(7,11,9,0.5); backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(8px); }
  .foot-icon { width:58px; height:58px; border-radius:14px; box-shadow:0 6px 18px rgba(0,0,0,0.5); }
  .wordmark { font-family:'Grotesk'; font-weight:700; font-size:40px; letter-spacing:-0.01em; color:#FFFFFF; }
  `;
}

// iPad Pro layout: text left, framed device right (uses the wide canvas).
function ipadFrameHTML(f) {
  const grass = f.grass || "day";
  const ipadCss = `
  .ipad-head { position:absolute; left:150px; top:0; bottom:0; width:1020px; display:flex; flex-direction:column; justify-content:center; z-index:5; }
  .ipad-head .ey { font-family:'Mono'; font-weight:700; font-size:42px; letter-spacing:0.14em; color:${GOLD}; text-transform:uppercase; margin-bottom:34px; text-shadow:0 2px 12px rgba(0,0,0,0.6); }
  .ipad-head .hl { font-family:'Grotesk'; font-weight:700; font-size:134px; line-height:1.02; letter-spacing:-0.026em; color:#fff; text-wrap:balance; text-shadow:0 4px 22px rgba(0,0,0,0.6); }
  .ipad-head .hl .accent { color:${GOLD}; }
  .ipad-head .sub { margin-top:40px; font-family:'Grotesk'; font-weight:500; font-size:52px; line-height:1.3; color:${P.slate}; max-width:900px; text-shadow:0 2px 14px rgba(0,0,0,0.7); }
  .ipad-dev { position:absolute; right:-160px; top:50%; transform:translateY(-50%); width:1140px; z-index:3;
      filter: drop-shadow(0 70px 90px rgba(0,0,0,0.62)) drop-shadow(0 10px 28px rgba(0,0,0,0.5)); }
  .ipad-foot { position:absolute; left:150px; bottom:100px; z-index:10; display:flex; align-items:center; gap:24px;
      padding:16px 30px 16px 16px; border-radius:999px; background:rgba(7,11,9,0.5); }
  .ipad-foot img { width:78px; height:78px; border-radius:18px; box-shadow:0 6px 18px rgba(0,0,0,0.4); }
  .ipad-foot .wm { font-family:'Grotesk'; font-weight:700; font-size:54px; color:#fff; }
  `;
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css(grass)}${ipadCss}</style></head>
  <body>
    <div class="grass"></div><div class="bloom"></div><div class="scrim"></div><div class="vignette"></div>
    <div class="ipad-head"><div class="ey">${f.eyebrow}</div><h1 class="hl">${headlineHTML(f.headline, f.accent)}</h1><p class="sub">${f.subline}</p></div>
    <img class="ipad-dev" src="${ensureFramed(f.screen)}"/>
    <div class="ipad-foot"><img src="${ICON_URI}"/><span class="wm">${config.wordmark}</span></div>
  </body></html>`;
}

function frameHTML(f) {
  const grass = f.grass || "day";
  const inner = (LAYOUTS[f.layout] || LAYOUTS.hero)(f);
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css(grass)}</style></head>
  <body>
    <div class="grass blur-far"></div>
    <div class="bloom"></div>
    <div class="scrim"></div>
    <div class="text-scrim"></div>
    <div class="vignette"></div>
    <div class="stage">${inner}</div>
  </body></html>`;
}

async function main() {
  fs.mkdirSync(OUT, { recursive: true });
  const tmp = path.join(OUT, ".tmp");
  fs.mkdirSync(tmp, { recursive: true });

  let frames = config.frames;
  if (frameFilter) {
    const want = frameFilter.split(",").map((s) => s.trim());
    frames = frames.filter((f) => want.includes(f.id));
  }

  const outDir = IPAD ? path.join(OUT, "ipad") : OUT;
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: DPR });

  for (const f of frames) {
    await page.setContent(IPAD ? ipadFrameHTML(f) : frameHTML(f), { waitUntil: "load" });
    await page.evaluate(async () => { await document.fonts.ready; });
    const raw = path.join(tmp, `${f.id}.png`);
    await page.screenshot({ path: raw, clip: { x: 0, y: 0, width: W, height: H } });
    const final = path.join(outDir, `${f.id}.png`);
    execFileSync("sips", ["-z", String(H), String(W), raw, "--out", final], { stdio: "ignore" });
    const dim = execFileSync("sips", ["-g", "pixelWidth", "-g", "pixelHeight", final]).toString();
    console.log(`✓ ${f.id}  ${/pixelWidth: (\d+)/.exec(dim)[1]}x${/pixelHeight: (\d+)/.exec(dim)[1]}  (${f.layout}/${f.grass || "day"})`);
  }

  await browser.close();
  fs.rmSync(tmp, { recursive: true, force: true });
  console.log(`\nRendered ${frames.length} frame(s) → ${outDir}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
