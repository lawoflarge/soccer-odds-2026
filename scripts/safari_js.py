#!/usr/bin/env python3
"""Run JS in the (logged-in) Safari tab whose URL contains <url_sub>. JS from stdin.
Usage: echo '<js returning a string>' | python3 safari_js.py <url_sub> [--goto URL]
The JS is run as eval(atob(...)) so quoting/newlines are safe. Return a string from your JS."""
import sys, base64, subprocess, time
url_sub = sys.argv[1]
goto = None
if "--goto" in sys.argv:
    goto = sys.argv[sys.argv.index("--goto")+1]

def osa(script):
    r = subprocess.run(["osascript","-e",script], capture_output=True, text=True)
    return r.returncode, r.stdout.strip(), r.stderr.strip()

def find_tab_clause():
    return ('set theTab to missing value\n'
            'repeat with w in windows\n repeat with t in tabs of w\n'
            f'  if (URL of t) contains "{url_sub}" then set theTab to t\n'
            ' end repeat\n end repeat\n')

if goto:
    code,out,err = osa(f'tell application "Safari"\n{find_tab_clause()}'
                       f'if theTab is missing value then return "TAB_NOT_FOUND"\n'
                       f'set URL of theTab to "{goto}"\nend tell')
    if out=="TAB_NOT_FOUND": print("TAB_NOT_FOUND"); sys.exit(2)
    time.sleep(4)

js = sys.stdin.read()
if not js.strip():
    sys.exit(0)
b64 = base64.b64encode(js.encode()).decode()
script = (f'tell application "Safari"\n{find_tab_clause()}'
          f'if theTab is missing value then return "TAB_NOT_FOUND"\n'
          f'do JavaScript "eval(decodeURIComponent(escape(atob(\\"{b64}\\"))))" in theTab\nend tell')
code,out,err = osa(script)
print(out if out else ("ERR:"+err))
