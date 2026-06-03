#!/usr/bin/env python3
"""Register bundle ID + create/install an App Store provisioning profile for Soccer Odds 2026."""
import jwt as pyjwt, time, json, sys, base64, pathlib, urllib.request, urllib.error, urllib.parse

KEY_ID="REDACTED_ASC_KEY_ID"; ISSUER_ID="REDACTED_ASC_ISSUER_ID"
KEY_PATH=pathlib.Path.home()/".appstoreconnect/private_keys/AuthKey_REDACTED_ASC_KEY_ID.p8"
TEAM_ID="R95M36AU2X"; BUNDLE_ID="com.lawoflarge.worldcup2026odds"; BUNDLE_NAME="SoccerOdds2026"
CERT_SHA="REDACTED_ASC_CERT_SHA"
PROFILES_DIR=pathlib.Path.home()/"Library/MobileDevice/Provisioning Profiles"
TS=int(time.time())

def jwtok():
    now=int(time.time())
    return pyjwt.encode({"iss":ISSUER_ID,"iat":now,"exp":now+600,"aud":"appstoreconnect-v1"},
                        KEY_PATH.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"})
def api(method,path,body=None):
    url=f"https://api.appstoreconnect.apple.com{path}"; data=None
    h={"Authorization":f"Bearer {jwtok()}"}
    if body is not None: data=json.dumps(body).encode(); h["Content-Type"]="application/json"
    req=urllib.request.Request(url,data=data,method=method,headers=h)
    try:
        with urllib.request.urlopen(req,timeout=30) as r:
            raw=r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code} {method} {path}: {e.read().decode(errors='replace')}",file=sys.stderr); raise

def ensure_bundle():
    q=urllib.parse.quote(BUNDLE_ID)
    r=api("GET",f"/v1/bundleIds?filter[identifier]={q}&limit=10")
    for b in r.get("data",[]):
        if b["attributes"]["identifier"]==BUNDLE_ID:
            print(f"  bundleId exists: {b['id']}"); return b["id"]
    body={"data":{"type":"bundleIds","attributes":{"identifier":BUNDLE_ID,"name":BUNDLE_NAME,"platform":"IOS","seedId":TEAM_ID}}}
    r=api("POST","/v1/bundleIds",body); print(f"  registered bundleId: {r['data']['id']}"); return r["data"]["id"]

def pick_cert():
    r=api("GET","/v1/certificates?filter[certificateType]=DISTRIBUTION&limit=20")
    items=[c for c in r.get("data",[]) if c["attributes"]["certificateType"]=="DISTRIBUTION"]
    if not items: raise SystemExit("no DISTRIBUTION cert")
    items.sort(key=lambda c:c["attributes"]["expirationDate"],reverse=True)
    print(f"  cert {items[0]['id']} exp {items[0]['attributes']['expirationDate']}"); return items[0]["id"]

def make_profile(name,bres,cres):
    ex=api("GET",f"/v1/profiles?filter[name]={urllib.parse.quote(name)}&limit=5")
    if ex.get("data"): print(f"  profile '{name}' reused"); return ex["data"][0]
    body={"data":{"type":"profiles","attributes":{"name":name,"profileType":"IOS_APP_STORE"},
          "relationships":{"bundleId":{"data":{"type":"bundleIds","id":bres}},
                           "certificates":{"data":[{"type":"certificates","id":cres}]}}}}
    r=api("POST","/v1/profiles",body); print(f"  created profile '{name}'"); return r["data"]

def install(p):
    PROFILES_DIR.mkdir(parents=True,exist_ok=True)
    t=PROFILES_DIR/f"{p['attributes']['uuid']}.mobileprovision"
    t.write_bytes(base64.b64decode(p["attributes"]["profileContent"])); print(f"  installed -> {t}")

print("== bundle id =="); bres=ensure_bundle()
print("== cert =="); cres=pick_cert()
print("== profile =="); name=f"SoccerOdds2026 ios_app_store {TS}"
p=make_profile(name,bres,cres); install(p)
print("\nPROFILE_NAME="+name)
print("CERT_SHA="+CERT_SHA)
