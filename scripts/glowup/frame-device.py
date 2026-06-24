#!/usr/bin/env python3
"""Embed a raw iPhone 16 Pro Max simulator screenshot into a REAL device frame.

Uses Koubou's Apple-accurate Black-Titanium portrait frame (1470x3000, screen
slot at offset 80,80 sized 1320x2868) — the dark titanium body matches Soccer
Odds' dark "Stadion Premium" UI and reads as premium on bright grass. Soccer
Odds uses a standard bottom TabView (no top web-parity nav band), so we do NOT
strip — the full native capture (incl. the tab bar) fills the slot. Output is a
transparent PNG of just the framed device, trimmed to bbox.

  python3 frame-device.py <in.png> <out.png>
"""
import sys
from PIL import Image, ImageDraw

SCREEN_RADIUS = 132          # round the capture corners to match the frame cutout

FRAME = "/Users/levinschwab/.koubou/frames/iPhone 16 Pro Max - Black Titanium - Portrait.png"
OFFX, OFFY = 80, 80          # screen slot offset in the frame (Frames.json)
SW, SH = 1320, 2868          # screen slot size (native iPhone 16 Pro Max @3x)


def frame_one(src, dst):
    frame = Image.open(FRAME).convert("RGBA")
    shot = Image.open(src).convert("RGBA")
    if shot.size != (SW, SH):
        shot = shot.resize((SW, SH), Image.LANCZOS)
    # round the capture's corners so they sit cleanly inside the frame cutout
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot.width, shot.height), radius=SCREEN_RADIUS, fill=255)
    shot.putalpha(mask)
    canvas = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    canvas.paste(shot, (OFFX, OFFY), shot)
    canvas.alpha_composite(frame)          # opaque body over the screen edges
    canvas = canvas.crop(canvas.getbbox())  # trim transparent margins
    canvas.save(dst)
    print(f"framed {dst} {canvas.size}")


if __name__ == "__main__":
    frame_one(sys.argv[1], sys.argv[2])
