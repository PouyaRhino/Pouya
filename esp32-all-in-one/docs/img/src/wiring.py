#!/usr/bin/env python3
"""Generate the Pebble wiring diagram (full + one image per build step) as SVG.

Run:  python3 wiring.py <outdir>     then render with render.js (Playwright).
Pin numbers follow firmware/bringup/include/pins.h. Change both if a pin moves.
"""
import sys, os

W, H = 2400, 1810

# ---------- colours ----------
C = dict(
    v5="#E53935", v33="#FB8C00", gnd="#1F1F1F",
    blue="#1E88E5", yellow="#FDD835", green="#43A047", purple="#8E24AA",
    grey="#9E9E9E", brown="#8D6E63", white="#FFFFFF", pink="#EC407A",
    cyan="#00ACC1", teal="#00897B", lime="#7CB342",
)
RAIL = {"3V3": (C["v33"], "#fff"), "5V": (C["v5"], "#fff"), "GND": (C["gnd"], "#fff")}

out = []          # (steps, svg) tuples
def add(steps, s):
    out.append((steps, s))

def esc(t):
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

# ---------- primitives ----------
def wire(d, color, steps, width=7):
    add(steps, f'<path d="{d}" fill="none" stroke="#2b2b2b" stroke-width="{width+3}" '
               f'stroke-linecap="round" stroke-linejoin="round"/>'
               f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
               f'stroke-linecap="round" stroke-linejoin="round"/>')

def poly(pts):
    return "M" + " L".join(f"{x},{y}" for x, y in pts)

def dot(x, y, steps):
    add(steps, f'<circle cx="{x}" cy="{y}" r="9" fill="#2b2b2b"/>')

def text(x, y, t, size=22, weight=500, fill="#2b2b2b", anchor="start", steps=("all",), extra=""):
    add(steps, f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" '
               f'text-anchor="{anchor}" {extra}>{esc(t)}</text>')

def pill(x, y, label, steps, anchor="start"):
    bg, fg = RAIL[label]
    w = 22 + 14 * len(label)
    x0 = x if anchor == "start" else x - w
    add(steps, f'<rect x="{x0}" y="{y-17}" width="{w}" height="34" rx="17" fill="{bg}" stroke="#2b2b2b" stroke-width="2"/>'
               f'<text x="{x0 + w/2}" y="{y+8}" font-size="20" font-weight="700" fill="{fg}" text-anchor="middle">{label}</text>')

def badge(x, y, label, steps, bg="#FF6D00", fg="#fff"):
    w = 20 + 12.5 * len(label)
    add(steps, f'<rect x="{x}" y="{y}" width="{w}" height="30" rx="8" fill="{bg}"/>'
               f'<text x="{x + w/2}" y="{y+21}" font-size="18" font-weight="800" fill="{fg}" text-anchor="middle" letter-spacing="0.5">{esc(label)}</text>')
    return w

def module(x, y, w, h, title, sub, head, steps, pins, side="right", chips=()):
    """pins: list of (label, abs_y, kind, colour)  kind: sig | 3V3 | 5V | GND | nc:<note>"""
    s = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="#fff" stroke="#2b2b2b" stroke-width="3"/>',
         f'<path d="M{x},{y+16} a16,16 0 0 1 16,-16 h{w-32} a16,16 0 0 1 16,16 v38 h-{w} z" fill="{head}"/>',
         f'<text x="{x+16}" y="{y+36}" font-size="24" font-weight="800" fill="#fff">{esc(title)}</text>']
    if sub:
        s.append(f'<text x="{x+16}" y="{y+h-16}" font-size="18" fill="#666">{esc(sub)}</text>')
    add(steps, "".join(s))
    cx = x + w + 4
    for i, (lab, py, kind, col) in enumerate(pins):
        ex = x + w if side == "right" else x
        tx = ex - 14 if side == "right" else ex + 14
        anc = "end" if side == "right" else "start"
        text(tx, py + 7, lab, 20, 700, "#2b2b2b", anc, steps)
        add(steps, f'<circle cx="{ex}" cy="{py}" r="7" fill="#C9A227" stroke="#2b2b2b" stroke-width="2"/>')
        sgn = 1 if side == "right" else -1
        if kind in RAIL:
            wire(f"M{ex},{py} L{ex + sgn*46},{py}", RAIL[kind][0], steps, 5)
            pill(ex + sgn*50, py, kind, steps, "start" if side == "right" else "end")
        elif kind.startswith("nc"):
            note = kind[3:] or "leave unconnected"
            add(steps, f'<path d="M{ex},{py} L{ex + sgn*26},{py}" stroke="#999" stroke-width="3" stroke-dasharray="4 4"/>')
            text(ex + sgn*34, py + 7, "✕ " + note, 17, 500, "#888", "start" if side == "right" else "end", steps)
    cy = y + h - 16
    for c in chips:
        pass

def chip(x, y, label, steps, bg, fg="#fff"):
    return badge(x, y, label, steps, bg, fg)

# ======================================================================
# Layout
# ======================================================================
S_ESP, S_DISP, S_SENS, S_CAM, S_AUD, S_RAD, S_PWR = "esp", "disp", "sens", "cam", "aud", "rad", "pwr"
ALL = ("all",)

# regions
add(ALL, f'<rect x="30" y="112" width="{W-60}" height="1006" rx="34" fill="#FBF3E4" stroke="#E2D3B5" stroke-width="3"/>')
add(ALL, f'<rect x="30" y="1214" width="{W-60}" height="570" rx="34" fill="#E9ECEF" stroke="#C9CED4" stroke-width="3"/>')
text(64, 1084, "HEAD", 40, 900, "#B88A3A")
text(200, 1084, "ESP32 board, face, audio, top sensors", 20, 500, "#B88A3A")
text(64, 1264, "STAND", 40, 900, "#5F6B78")
text(64, 1296, "battery, charger, radar, room sensors", 20, 500, "#5F6B78")

# ---------- ESP32 board ----------
EX0, EX1, EY0, EY1 = 980, 1420, 262, 1000
add(ALL, f'<rect x="{EX0}" y="{EY0}" width="{EX1-EX0}" height="{EY1-EY0}" rx="18" fill="#1F3B2D" stroke="#2b2b2b" stroke-width="3"/>'
         f'<rect x="1112" y="420" width="176" height="290" rx="10" fill="#C7CCD1" stroke="#7d858c" stroke-width="2"/>'
         f'<text x="1200" y="500" font-size="24" font-weight="800" fill="#3a4148" text-anchor="middle">ESP32-S3</text>'
         f'<text x="1200" y="530" font-size="20" font-weight="700" fill="#3a4148" text-anchor="middle">N16R8</text>'
         f'<text x="1200" y="580" font-size="18" font-weight="600" fill="#3a4148" text-anchor="middle">CAM board</text>'
         f'<text x="1200" y="640" font-size="15" fill="#3a4148" text-anchor="middle">16 MB flash</text>'
         f'<text x="1200" y="662" font-size="15" fill="#3a4148" text-anchor="middle">8 MB PSRAM</text>')
text(1200, 806, "Never wire: GPIO 35-37 (PSRAM),", 16, 600, "#FFCDD2", "middle")
text(1200, 828, "45, 44, 19/20 (USB), 26-32", 16, 600, "#FFCDD2", "middle")

def esp_pin(x, y, label, side, steps=ALL):
    add(steps, f'<rect x="{x-8}" y="{y-8}" width="16" height="16" rx="3" fill="#C9A227" stroke="#2b2b2b" stroke-width="2"/>')
    if side == "left":
        text(x + 18, y + 7, label, 19, 700, "#fff", "start", steps)
    elif side == "right":
        text(x - 18, y + 7, label, 19, 700, "#fff", "end", steps)
    else:  # bottom: rotated
        add(steps, f'<text x="{x+7}" y="{y-18}" font-size="18" font-weight="700" fill="#fff" '
                   f'text-anchor="start" transform="rotate(-90 {x+7} {y-18})">{esc(label)}</text>')

# ---------- Camera (top, ribbon) ----------
add((S_CAM,), f'<rect x="1150" y="{EY0-22}" width="100" height="60" fill="#B8860B" opacity="0.85"/>'
              f'<rect x="1080" y="128" width="240" height="96" rx="14" fill="#fff" stroke="#2b2b2b" stroke-width="3"/>'
              f'<circle cx="1135" cy="176" r="30" fill="#222"/><circle cx="1135" cy="176" r="14" fill="#3949AB"/>'
              f'<text x="1180" y="168" font-size="24" font-weight="800" fill="#2b2b2b">OV5640</text>'
              f'<text x="1180" y="194" font-size="16" fill="#666">78 mm ribbon</text>')
add((S_CAM,), f'<rect x="1140" y="224" width="120" height="40" fill="#C8A04A" stroke="#2b2b2b" stroke-width="2"/>')
text(1056, 160, "Ribbon into the board's camera socket.", 19, 700, "#2b2b2b", "end", (S_CAM,))
text(1056, 186, "No wires: uses GPIO 4-13, 15-18 on the board.", 19, 500, "#555", "end", (S_CAM,))
text(1056, 212, "Gold contacts face the socket contacts, latch shut.", 19, 500, "#555", "end", (S_CAM,))

# ---------- Display (left) ----------
DX, DW = 120, 400
dp = [("VCC", 232, "3V3", None), ("GND", 268, "GND", None),
      ("SCL", 310, "sig", C["green"]), ("SDA", 350, "sig", C["purple"]),
      ("CS", 390, "sig", C["grey"]), ("DC", 430, "sig", C["brown"]),
      ("BL", 470, "sig", C["white"]), ("RST", 510, "sig", C["pink"])]
module(DX, 140, DW, 400, "Display ST7789", "2.01\" 240×296 SPI · 3.3 V", "#3949AB", (S_DISP,), dp)
espL = {310: "21  LCD SCLK", 350: "47  LCD MOSI", 390: "14  LCD CS", 430: "38  LCD DC", 470: "39  LCD BL", 510: "EN  (reset)"}
for lab, py, kind, col in dp:
    if kind == "sig":
        wire(f"M{DX+DW},{py} L{EX0},{py}", col, (S_DISP,))
        esp_pin(EX0, py, espL[py], "left")
text(DX + 16, 532 - 20 - 120, "", 1)

# ---------- TTP223 touch (left) ----------
module(DX, 600, DW, 170, "TTP223 touch pad", "head pat · glue under the top", "#00838F", (S_RAD,),
       [("OUT", 680, "sig", C["cyan"]), ("VCC", 712, "3V3", None), ("GND", 744, "GND", None)])
wire(f"M{DX+DW},680 L{EX0},680", C["cyan"], (S_RAD,))
esp_pin(EX0, 680, "3   TOUCH", "left")

# ---------- BH1750 (left) ----------
module(DX, 810, DW, 220, "BH1750 light", "4 mm top window · I2C 0x23", "#6D4C41", (S_SENS,),
       [("SDA", 880, "sig", C["blue"]), ("SCL", 915, "sig", C["yellow"]),
        ("VCC", 950, "3V3", None), ("GND", 985, "GND", None), ("ADDR", 1015, "nc:open = 0x23", None)])

# ---------- bottom ESP pins = the 8 neck wires ----------
NX = [1046, 1090, 1134, 1178, 1222, 1266, 1310, 1354]
neck = [("4  SDA", C["blue"], S_SENS), ("5  SCL", C["yellow"], S_SENS), ("3V3 out", C["v33"], S_SENS),
        ("1  VBAT", C["purple"], S_PWR), ("43 RADAR RX", C["green"], S_RAD), ("46 RADAR OUT", C["white"], S_RAD),
        ("GND", C["gnd"], S_PWR), ("5V in", C["v5"], S_PWR)]
for x, (lab, col, st) in zip(NX, neck):
    esp_pin(x, EY1, lab, "bottom")

# BH1750 to the shared I2C bus (hop over SDA)
wire(f"M{DX+DW},880 L900,880 L900,1036 L1046,1036", C["blue"], (S_SENS,))
wire(f"M{DX+DW},915 L868,915 L868,1066 L1036,1066 A10,10 0 0 1 1056,1066 L1090,1066", C["yellow"], (S_SENS,))
dot(1046, 1036, (S_SENS,)); dot(1090, 1066, (S_SENS,))

# ---------- Mic (right) ----------
MX, MW = 1700, 380
module(MX, 150, MW, 330, "INMP441 mic", "under the 2 mm top hole · 3.3 V", "#00897B", (S_AUD,),
       [("VDD", 246, "3V3", None), ("GND", 274, "GND", None), ("SD", 304, "sig", C["white"]),
        ("WS", 344, "sig", C["purple"]), ("SCK", 384, "sig", C["green"]), ("L/R", 430, "GND", None)], side="left")
wire(f"M{EX1},304 L{MX},304", C["white"], (S_AUD,)); esp_pin(EX1, 304, "I2S DIN  2", "right")
wire(f"M{EX1},344 L{MX},344", C["purple"], (S_AUD,)); esp_pin(EX1, 344, "I2S WS  41", "right")
wire(f"M{EX1},384 L1490,384 A10,10 0 0 1 1510,384 L{MX},384", C["green"], (S_AUD,)); esp_pin(EX1, 384, "I2S BCLK  40", "right")

# ---------- Amp (right) ----------
module(MX, 530, MW, 350, "MAX98357A amp", "on the back lid, next to the speaker", "#C62828", (S_AUD,),
       [("VIN", 600, "5V", None), ("GND", 632, "GND", None), ("LRC", 670, "sig", C["purple"]),
        ("BCLK", 710, "sig", C["green"]), ("DIN", 750, "sig", C["blue"]),
        ("GAIN", 790, "nc", None), ("SD", 825, "nc", None)], side="left")
wire(f"M1500,344 L1500,670 L{MX},670", C["purple"], (S_AUD,)); dot(1500, 344, (S_AUD,))
wire(f"M1460,384 L1460,710 L{MX},710", C["green"], (S_AUD,)); dot(1460, 384, (S_AUD,))
wire(f"M{EX1},750 L{MX},750", C["blue"], (S_AUD,)); esp_pin(EX1, 750, "I2S DOUT  42", "right")

# speaker
for lab, py, col in (("+", 690, C["v5"]), ("−", 750, C["gnd"])):
    add((S_AUD,), f'<circle cx="{MX+MW}" cy="{py}" r="7" fill="#C9A227" stroke="#2b2b2b" stroke-width="2"/>')
    text(MX + MW - 14, py + 7, lab, 24, 800, "#2b2b2b", "end", (S_AUD,))
    wire(f"M{MX+MW},{py} L2190,{py}", col, (S_AUD,), 5)
add((S_AUD,), '<path d="M2190,670 L2230,670 L2290,620 L2290,820 L2230,770 L2190,770 Z" fill="#424242" stroke="#2b2b2b" stroke-width="3"/>'
              '<path d="M2312,670 q20,50 0,100 M2330,650 q32,70 0,140" fill="none" stroke="#424242" stroke-width="5" stroke-linecap="round"/>')
text(2240, 862, "Speaker 4 Ω 3 W", 20, 800, "#2b2b2b", "middle", (S_AUD,))
text(2240, 886, "on a PH 2.0 plug", 17, 500, "#666", "middle", (S_AUD,))
text(2240, 910, "never wire either side to GND", 17, 700, "#C62828", "middle", (S_AUD,))

# 5 V warning chips
badge(MX + MW - 116, 536, "5 V PART", (S_AUD,), "#FFEB3B", "#B71C1C")

# Schottky on 5V just under the board + tap for amp VIN
X5 = NX[7]
add((S_PWR,), f'<path d="M{X5-16},1056 L{X5+16},1056 L{X5},1030 Z" fill="#2b2b2b"/>'
              f'<rect x="{X5-18}" y="1024" width="36" height="6" fill="#2b2b2b"/>')
text(X5 + 28, 1040, "Schottky SS34 / 1N5819", 18, 800, "#2b2b2b", "start", (S_PWR,))
text(X5 + 28, 1062, "stripe toward the ESP32", 17, 500, "#555", "start", (S_PWR,))
badge(X5 + 270, 1022, "BUY", (S_PWR,))
dot(X5, 1088, (S_PWR,))
wire(f"M{X5},1088 L{X5+50},1088", C["v5"], (S_PWR,), 5)
add((S_PWR,), f'<rect x="{X5+54}" y="1071" width="222" height="34" rx="17" fill="{C["v5"]}" stroke="#2b2b2b" stroke-width="2"/>'
              f'<text x="{X5+165}" y="1095" font-size="18" font-weight="700" fill="#fff" text-anchor="middle">5V → amp VIN</text>')

# ---------- neck ----------
NECK_Y0, NECK_Y1 = 1136, 1196
add(ALL, f'<rect x="1018" y="{NECK_Y0}" width="364" height="{NECK_Y1-NECK_Y0}" rx="20" fill="#CFD8DC" stroke="#78909C" stroke-width="3" opacity="0.9"/>')
text(1400, 1160, "NECK POST · 12 mm bore", 20, 900, "#37474F")
text(1400, 1184, "8 wires · 30 AWG silicone · twist loosely · +3 cm slack", 18, 500, "#37474F")

# vertical runs from board to the stand turn points
turn = {0: ("L", 1380), 1: ("L", 1420), 2: ("L", 1460),
        3: ("R", 1620), 4: ("R", 1460), 5: ("R", 1420), 6: ("R", 1330), 7: ("R", 1290)}
# ---------- stand modules ----------
# AHT20 + BMP280 (left)
AX, AW = 360, 440
module(AX, 1300, AW, 240, "AHT20 + BMP280", "front wall · temp, humidity, pressure", "#5E35B1", (S_SENS,),
       [("SDA", 1380, "sig", C["blue"]), ("SCL", 1420, "sig", C["yellow"]), ("VCC", 1460, "sig", C["v33"]),
        ("GND", 1500, "GND", None)])
# fix the pin ys to match turns
for i in (0, 1, 2):
    pass

# radar (middle-right)
RX0, RW = 1640, 300
module(RX0, 1356, RW, 250, "HLK-LD2410C", "radar · antenna faces front", "#2E7D32", (S_RAD,),
       [("OUT", 1420, "sig", C["white"]), ("TX", 1460, "sig", C["green"]),
        ("VCC", 1500, "5V", None), ("GND", 1532, "GND", None), ("RX", 1564, "nc", None)], side="left")
badge(RX0 + RW - 116, 1362, "5 V PART", (S_RAD,), "#FFEB3B", "#B71C1C")
# radar 1k resistor
add((S_RAD,), f'<rect x="{RX0-130}" y="1448" width="64" height="24" rx="4" fill="#F5DEB3" stroke="#2b2b2b" stroke-width="2"/>'
              f'<rect x="{RX0-118}" y="1448" width="7" height="24" fill="#8D6E63"/><rect x="{RX0-104}" y="1448" width="7" height="24" fill="#222"/>'
              f'<rect x="{RX0-90}" y="1448" width="7" height="24" fill="#E53935"/>')
text(RX0 - 98, 1438, "1 kΩ", 18, 800, "#2b2b2b", "middle", (S_RAD,))

# IP5306 (far right, top)
IX0, IX1, IY0, IY1 = 2010, 2340, 1220, 1500
add((S_PWR,), f'<rect x="{IX0}" y="{IY0}" width="{IX1-IX0}" height="{IY1-IY0}" rx="16" fill="#fff" stroke="#2b2b2b" stroke-width="3"/>'
              f'<path d="M{IX0},{IY0+16} a16,16 0 0 1 16,-16 h{IX1-IX0-32} a16,16 0 0 1 16,16 v38 h-{IX1-IX0} z" fill="#EF6C00"/>'
              f'<text x="{IX0+16}" y="{IY0+36}" font-size="24" font-weight="800" fill="#fff">IP5306 Type-C</text>'
              f'<text x="{IX0+16}" y="{IY0+170}" font-size="17" fill="#666">charge + 5.1 V boost</text>'
              f'<text x="{IX0+16}" y="{IY0+194}" font-size="17" fill="#666">USB-C → back hole</text>')
badge(IX1 - 70, IY0 + 64, "BUY", (S_PWR,))
for lab, py in (("5V OUT", 1290), ("GND", 1330)):
    add((S_PWR,), f'<circle cx="{IX0}" cy="{py}" r="7" fill="#C9A227" stroke="#2b2b2b" stroke-width="2"/>')
    text(IX0 + 14, py + 7, lab, 20, 700, "#2b2b2b", "start", (S_PWR,))
# bottom pins B+, B-, KEY
for lab, x in (("B+", 2080), ("B−", 2200), ("KEY", 2300)):
    add((S_PWR,), f'<circle cx="{x}" cy="{IY1}" r="7" fill="#C9A227" stroke="#2b2b2b" stroke-width="2"/>')
    text(x, IY1 - 16, lab, 19, 700, "#2b2b2b", "middle", (S_PWR,))

# battery
BY0 = 1676
add((S_PWR,), f'<rect x="2010" y="{BY0}" width="330" height="100" rx="14" fill="#90A4AE" stroke="#2b2b2b" stroke-width="3"/>'
              f'<text x="2175" y="{BY0+44}" font-size="22" font-weight="800" fill="#1F2A30" text-anchor="middle">LiPo 3000 mAh</text>'
              f'<text x="2175" y="{BY0+70}" font-size="16" fill="#1F2A30" text-anchor="middle">PL103665 · JST 1.25 · CHECK POLARITY</text>')
wire(f"M2080,{IY1} L2080,{BY0}", C["v5"], (S_PWR,))
wire(f"M2200,{IY1} L2200,{BY0}", C["gnd"], (S_PWR,))
# KEY button
add((S_PWR,), '<path d="M2300,1500 L2300,1530 M2280,1530 L2320,1530 M2286,1548 L2314,1548 M2300,1548 L2300,1566" stroke="#2b2b2b" stroke-width="5" fill="none"/>'
              '<rect x="2284" y="1534" width="32" height="10" fill="#2b2b2b"/>')
wire("M2300,1566 L2300,1578", C["gnd"], (S_PWR,), 5)
text(2370, 1556, "", 1)
add((S_PWR,), '<g><circle cx="2300" cy="1590" r="0"/></g>')
text(2326, 1530, "tact", 15, 700, "#2b2b2b", "start", (S_PWR,))
text(2326, 1548, "button", 15, 700, "#2b2b2b", "start", (S_PWR,))
add((S_PWR,), f'<rect x="2280" y="1578" width="56" height="26" rx="13" fill="{C["gnd"]}"/>'
              f'<text x="2308" y="1597" font-size="16" font-weight="700" fill="#fff" text-anchor="middle">GND</text>')

# battery divider (VBAT)
DVX = 1960
dot(2080, 1620, (S_PWR,))
def res_v(x, y0, y1, label, steps):
    add(steps, f'<rect x="{x-12}" y="{y0}" width="24" height="{y1-y0}" rx="4" fill="#F5DEB3" stroke="#2b2b2b" stroke-width="2"/>'
               f'<rect x="{x-12}" y="{y0+8}" width="24" height="5" fill="#8D6E63"/><rect x="{x-12}" y="{y0+18}" width="24" height="5" fill="#222"/>'
               f'<rect x="{x-12}" y="{y0+28}" width="24" height="5" fill="#FDD835"/>')
    text(x - 22, (y0 + y1) / 2 + 7, label, 17, 800, "#2b2b2b", "end", steps)

# ---------- neck wires: board → stand ----------
for i, x in enumerate(NX):
    lab, col, st = neck[i]
    side, ty = turn[i]
    if i == 0:
        d = f"M{x},{EY1} L{x},{ty} L{AX+AW},{ty}"
    elif i == 1:
        d = f"M{x},{EY1} L{x},{ty} L{AX+AW},{ty}"
    elif i == 2:
        d = f"M{x},{EY1} L{x},{ty} L{AX+AW},{ty}"
    elif i == 3:   # VBAT → divider middle
        d = f"M{x},{EY1} L{x},{ty} L{DVX},{ty}"
    elif i == 4:   # radar RX43 ← TX via 1k
        d = f"M{x},{EY1} L{x},{ty} L{RX0-130},{ty} M{RX0-66},{ty} L{RX0},{ty}"
    elif i == 5:   # radar OUT
        d = f"M{x},{EY1} L{x},{ty} L{RX0},{ty}"
    elif i == 6:   # GND
        d = f"M{x},{EY1} L{x},{ty} L{IX0},{ty}"
    else:          # 5V
        d = f"M{x},{EY1} L{x},{ty} L{IX0},{ty}"
    wire(d, col, (st,))

# divider drawing: mid node at (DVX,1560), R1 to B+ (2080,1560), R2 down to GND
dot(DVX, 1620, (S_PWR,))
wire(f"M{DVX},1620 L2080,1620", C["v5"], (S_PWR,), 5)
add((S_PWR,), f'<rect x="1996" y="1608" width="50" height="24" rx="4" fill="#F5DEB3" stroke="#2b2b2b" stroke-width="2"/>'
              f'<rect x="2006" y="1608" width="5" height="24" fill="#8D6E63"/><rect x="2016" y="1608" width="5" height="24" fill="#222"/><rect x="2026" y="1608" width="5" height="24" fill="#FDD835"/>')
text(2021, 1600 - 0, "100k", 16, 800, "#2b2b2b", "middle", (S_PWR,))
wire(f"M{DVX},1620 L{DVX},1740", C["gnd"], (S_PWR,), 5)
res_v(DVX, 1650, 1700, "100k", (S_PWR,))
add((S_PWR,), f'<rect x="{DVX-30}" y="1740" width="60" height="28" rx="14" fill="{C["gnd"]}"/>'
              f'<text x="{DVX}" y="1760" font-size="16" font-weight="700" fill="#fff" text-anchor="middle">GND</text>')
text(DVX - 20, 1652, "battery sense divider", 17, 800, "#2b2b2b", "end", (S_PWR,))
text(DVX - 20, 1520, "", 1)
badge(DVX - 300, 1720, "BUY resistors", (S_PWR,))

# ---------- legend / notes (stand, middle) ----------
LX, LY = 80, 1536
add(ALL, f'<rect x="{LX}" y="{LY}" width="900" height="236" rx="18" fill="#fff" stroke="#C9CED4" stroke-width="2"/>')
text(LX + 24, LY + 40, "How to read this", 24, 900)
yy = LY + 78
for lab, desc in (("5V", "IP5306 5 V out (radar, amp; ESP32 5V pin through the diode)"),
                  ("3V3", "ESP32 3V3 pin (display, mic, sensors, touch)"),
                  ("GND", "any GND pin: all grounds are joined")):
    pill(LX + 24, yy - 7, lab, ALL)
    text(LX + 110, yy, desc, 19, 500)
    yy += 36
add(ALL, f'<circle cx="{LX+44}" cy="{yy-7}" r="9" fill="#2b2b2b"/>')
text(LX + 110, yy, "dot = wires joined · a hop = crossing, not joined", 19, 500)
yy += 36
w = badge(LX + 24, yy - 27, "BUY", ALL)
text(LX + 110, yy - 5, "still to buy · signal wire colours are only a suggestion", 19, 500)

# ---------- title ----------
text(40, 70, "Pebble desk pet · wiring", 46, 900, "#1b1b1b")
text(620, 70, "ESP32-S3 N16R8 · pins match firmware/bringup/include/pins.h", 22, 500, "#666")

# ======================================================================
STEPS = {
    "full": None,
    "1-board": {S_ESP},
    "2-display": {S_DISP},
    "3-sensors": {S_SENS},
    "4-camera": {S_CAM},
    "5-audio": {S_AUD},
    "6-radar-touch": {S_RAD},
    "7-power": {S_PWR},
}
TITLES = {
    "1-board": ("Step 1 · Board alone", "Plug in native USB, flash bring-up, check PSRAM 8 MB"),
    "2-display": ("Step 2 · Display", "6 signal wires + 3V3 + GND · test: d"),
    "3-sensors": ("Step 3 · Sensors (I2C)", "SDA 4, SCL 5 shared · test: s, then e"),
    "4-camera": ("Step 4 · Camera", "Ribbon only · test: c"),
    "5-audio": ("Step 5 · Amp + speaker + mic", "One I2S bus · amp needs 5 V · test: t, m"),
    "6-radar-touch": ("Step 6 · Radar + touch", "Radar needs 5 V and a 1k on its TX · test: r, k"),
    "7-power": ("Step 7 · Power", "IP5306, battery, diode, divider · test: b, then a"),
}

def build(name, active):
    parts = []
    for steps, s in out:
        on = active is None or "all" in steps or bool(set(steps) & active)
        if active is not None and "all" in steps:
            parts.append(s)
        elif on:
            parts.append(s)
        else:
            parts.append(f'<g opacity="0.12">{s}</g>')
    banner = ""
    if name in TITLES:
        t, sub = TITLES[name]
        banner = (f'<rect x="1360" y="20" width="1010" height="76" rx="18" fill="#1b1b1b"/>'
                  f'<text x="1384" y="58" font-size="28" font-weight="900" fill="#FFD54F">{esc(t)}</text>'
                  f'<text x="1384" y="86" font-size="20" font-weight="500" fill="#fff">{esc(sub)}</text>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
            f'font-family="Inter, DejaVu Sans, sans-serif">'
            f'<rect width="{W}" height="{H}" fill="#F7F5F0"/>' + "".join(parts) + banner + "</svg>")

if __name__ == "__main__":
    od = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(od, exist_ok=True)
    for name, act in STEPS.items():
        with open(os.path.join(od, f"wiring-{name}.svg"), "w") as f:
            f.write(build(name, act))
    print("ok")
