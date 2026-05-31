#!/usr/bin/env python3
import jwt as pyjwt, time, json, sys, pathlib, hashlib, urllib.request, urllib.error
KEY_ID="REDACTED_ASC_KEY_ID"; ISSUER_ID="REDACTED_ASC_ISSUER_ID"
KEY_PATH=pathlib.Path.home()/".appstoreconnect/private_keys/AuthKey_REDACTED_ASC_KEY_ID.p8"
APP_ID="6775278722"; DISPLAY_TYPE="APP_IPHONE_67"
SHOTS=sorted((pathlib.Path(__file__).parent.parent/"store/screenshots").glob("*.png"))
def jwtok():
    n=int(time.time()); return pyjwt.encode({"iss":ISSUER_ID,"iat":n,"exp":n+600,"aud":"appstoreconnect-v1"},KEY_PATH.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"})
def api(m,p,b=None):
    h={"Authorization":f"Bearer {jwtok()}"}; d=None
    if b is not None: d=json.dumps(b).encode(); h["Content-Type"]="application/json"
    r=urllib.request.Request(f"https://api.appstoreconnect.apple.com{p}",data=d,method=m,headers=h)
    try:
        with urllib.request.urlopen(r,timeout=60) as x: raw=x.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e: print(f"HTTP {e.code} {m} {p}\n{e.read().decode()}",file=sys.stderr); raise
vs=api("GET",f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=5"); vid=vs["data"][0]["id"]
vlocs=api("GET",f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=20")
vloc=next(x for x in vlocs["data"] if x["attributes"]["locale"]=="en-US")["id"]
sets=api("GET",f"/v1/appStoreVersionLocalizations/{vloc}/appScreenshotSets?limit=20")
ex=next((s for s in sets["data"] if s["attributes"]["screenshotDisplayType"]==DISPLAY_TYPE),None)
if ex: setid=ex["id"]; print("reuse set",setid)
else:
    r=api("POST","/v1/appScreenshotSets",{"data":{"type":"appScreenshotSets","attributes":{"screenshotDisplayType":DISPLAY_TYPE},"relationships":{"appStoreVersionLocalization":{"data":{"type":"appStoreVersionLocalizations","id":vloc}}}}}); setid=r["data"]["id"]; print("created set",setid)
for s in api("GET",f"/v1/appScreenshotSets/{setid}/appScreenshots?limit=50")["data"]:
    api("DELETE",f"/v1/appScreenshots/{s['id']}")
for path in SHOTS:
    data=path.read_bytes()
    r=api("POST","/v1/appScreenshots",{"data":{"type":"appScreenshots","attributes":{"fileName":path.name,"fileSize":len(data)},"relationships":{"appScreenshotSet":{"data":{"type":"appScreenshotSets","id":setid}}}}})
    sid=r["data"]["id"]; ops=r["data"]["attributes"]["uploadOperations"]
    for op in ops:
        chunk=data[op["offset"]:op["offset"]+op["length"]]
        rq=urllib.request.Request(op["url"],method=op["method"],data=chunk)
        for hd in op["requestHeaders"]: rq.add_header(hd["name"],hd["value"])
        with urllib.request.urlopen(rq,timeout=120) as resp: assert resp.status in (200,201,204)
    api("PATCH",f"/v1/appScreenshots/{sid}",{"data":{"type":"appScreenshots","id":sid,"attributes":{"uploaded":True,"sourceFileChecksum":hashlib.md5(data).hexdigest()}}})
    print("uploaded",path.name)
print("DONE",len(SHOTS),"screenshots")
