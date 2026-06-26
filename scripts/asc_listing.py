#!/usr/bin/env python3
import jwt as pyjwt, time, json, sys, pathlib, urllib.request, urllib.error
import os
_ef = pathlib.Path(__file__).parent / ".asc.env"
if _ef.exists():
    for _ln in _ef.read_text().splitlines():
        if "=" in _ln and not _ln.lstrip().startswith("#"):
            _k, _v = _ln.split("=", 1); os.environ.setdefault(_k.strip(), _v.strip())
KEY_ID = os.environ.get("ASC_KEY_ID", "")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "")
KEY_PATH = pathlib.Path(os.environ.get("ASC_KEY_PATH", str(pathlib.Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{KEY_ID}.p8")))
APP_ID="6775278722"
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
def jwtok():
    n=int(time.time())
    return pyjwt.encode({"iss":ISSUER_ID,"iat":n,"exp":n+600,"aud":"appstoreconnect-v1"},KEY_PATH.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"})
def api(m,p,b=None):
    h={"Authorization":f"Bearer {jwtok()}"}; d=None
    if b is not None: d=json.dumps(b).encode(); h["Content-Type"]="application/json"
    r=urllib.request.Request(f"https://api.appstoreconnect.apple.com{p}",data=d,method=m,headers=h)
    try:
        with urllib.request.urlopen(r,timeout=30) as x: raw=x.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code} {m} {p}\n{e.read().decode(errors='replace')}",file=sys.stderr); raise

ai=api("GET",f"/v1/apps/{APP_ID}/appInfos?limit=5")
info=next((x for x in ai["data"] if x["attributes"]["state"] in ("PREPARE_FOR_SUBMISSION","READY_FOR_SUBMISSION")),ai["data"][0])
iid=info["id"]; print("appInfo",iid)
try:
    api("PATCH",f"/v1/appInfos/{iid}",{"data":{"type":"appInfos","id":iid,"relationships":{"primaryCategory":{"data":{"type":"appCategories","id":"SPORTS"}}}}})
    print("  category=SPORTS")
except urllib.error.HTTPError as e: print("  WARN category:",e)
locs=api("GET",f"/v1/appInfos/{iid}/appInfoLocalizations?limit=20")
en=next((x for x in locs["data"] if x["attributes"]["locale"]=="en-US"),None)
api("PATCH",f"/v1/appInfoLocalizations/{en['id']}",{"data":{"type":"appInfoLocalizations","id":en["id"],"attributes":{"name":NAME,"subtitle":SUBTITLE,"privacyPolicyUrl":PRIVACY_URL}}})
print("  subtitle + privacy url set")
vs=api("GET",f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=5")
v=vs["data"][0]; vid=v["id"]; print("version",v["attributes"]["versionString"],vid)
vlocs=api("GET",f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=20")
env=next((x for x in vlocs["data"] if x["attributes"]["locale"]=="en-US"),None)
api("PATCH",f"/v1/appStoreVersionLocalizations/{env['id']}",{"data":{"type":"appStoreVersionLocalizations","id":env["id"],"attributes":{"description":DESCRIPTION,"keywords":KEYWORDS,"marketingUrl":MARKETING_URL,"supportUrl":SUPPORT_URL,"promotionalText":PROMO}}})
print(f"  desc={len(DESCRIPTION)}c keywords={len(KEYWORDS)}c set")
print("VERSION_ID="+vid)
print("VLOC_EN_ID="+env["id"])
