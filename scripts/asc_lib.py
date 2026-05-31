import jwt as pyjwt, time, json, pathlib, urllib.request, urllib.error, sys
KEY_ID="8XWLD2B2RQ"; ISSUER_ID="538cb0d4-b8c6-4bc7-8b59-75da5d2b9411"
KEY_PATH=pathlib.Path.home()/".appstoreconnect/private_keys/AuthKey_8XWLD2B2RQ.p8"
APP_ID="6775278722"; VERSION_ID="0b8f4d83-296e-4468-8bc5-75f80b0061e6"
def jwtok():
    n=int(time.time()); return pyjwt.encode({"iss":ISSUER_ID,"iat":n,"exp":n+600,"aud":"appstoreconnect-v1"},KEY_PATH.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"})
def api(m,p,b=None):
    h={"Authorization":f"Bearer {jwtok()}"}; d=None
    if b is not None: d=json.dumps(b).encode(); h["Content-Type"]="application/json"
    r=urllib.request.Request(f"https://api.appstoreconnect.apple.com{p}",data=d,method=m,headers=h)
    try:
        with urllib.request.urlopen(r,timeout=40) as x: raw=x.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code} {m} {p}\n{e.read().decode(errors='replace')[:400]}",file=sys.stderr); raise
